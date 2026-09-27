import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import * as djwt from "https://deno.land/x/djwt@v2.8/mod.ts"

interface NotificationPayload {
  title: string
  body: string
  type: string
  match_id?: string
  tournament_id?: string
}

async function getAccessToken(serviceAccount: any): Promise<string> {
  const scope = "https://www.googleapis.com/auth/firebase.messaging";
  
  // Create JWT payload
  const payload = {
    iss: serviceAccount.client_email,
    scope: scope,
    aud: serviceAccount.token_uri,
    exp: Math.floor(Date.now() / 1000) + 3600,
    iat: Math.floor(Date.now() / 1000),
  };

  // Create private key crypto key
  const privateKeyStr = serviceAccount.private_key.replace(/\\n/g, '\n');
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKeyStr.substring(
    privateKeyStr.indexOf(pemHeader) + pemHeader.length,
    privateKeyStr.indexOf(pemFooter)
  ).replace(/\s/g, "");
  
  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    true,
    ["sign"]
  );

  const jwt = await djwt.create(
    { alg: "RS256", typ: "JWT" },
    payload,
    cryptoKey
  );

  // Exchange JWT for Access Token
  const res = await fetch(serviceAccount.token_uri, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  if (data.error) {
    throw new Error(`Error getting access token: ${data.error_description}`);
  }
  return data.access_token;
}

serve(async (req) => {
  try {
    const payload: NotificationPayload = await req.json()

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Fetch all FCM tokens
    const { data: tokensData, error } = await supabaseAdmin
      .from('fcm_tokens')
      .select('token')

    if (error) {
      throw error
    }

    const tokens = tokensData.map((t) => t.token)

    if (tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No tokens found' }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      })
    }

    // Use Firebase Service Account JSON for HTTP v1 API
    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountStr) {
      return new Response(JSON.stringify({ message: 'FIREBASE_SERVICE_ACCOUNT not configured.' }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      })
    }

    const serviceAccount = JSON.parse(serviceAccountStr)
    const projectId = serviceAccount.project_id
    const accessToken = await getAccessToken(serviceAccount)

    const responses = []
    
    // HTTP v1 API only allows sending to one token at a time unless using topics or multicast logic
    // We loop over tokens and send individually for simplicity
    for (const token of tokens) {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: token,
            notification: {
              title: payload.title,
              body: payload.body,
            },
            data: {
              type: payload.type,
              match_id: payload.match_id ?? "",
              tournament_id: payload.tournament_id ?? "",
            },
          }
        }),
      })
      responses.push(await res.json())
    }

    return new Response(
      JSON.stringify({ message: 'Notifications sent', responses }),
      { headers: { "Content-Type": "application/json" } },
    )
  } catch (err) {
    return new Response(String(err?.message ?? err), { status: 500 })
  }
})
