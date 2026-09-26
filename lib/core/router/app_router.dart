import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/models/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/member_dashboard.dart';
import '../../features/dashboard/presentation/screens/scaffold_with_nav_bar.dart';
import '../../features/dashboard/presentation/screens/notification_screen.dart';
import '../../features/matches/presentation/screens/match_detail_screen.dart';
import '../../features/matches/presentation/screens/match_form_screen.dart';
import '../../features/matches/presentation/screens/match_squads_screen.dart';
import '../../features/members/presentation/screens/member_management_screen.dart';
import '../../features/scoring/presentation/screens/charts_screen.dart';
import '../../features/scoring/presentation/screens/live_scorer_screen.dart';
import '../../features/scoring/presentation/screens/live_viewer_screen.dart';
import '../../features/scoring/presentation/screens/live_matches_screen.dart';
import '../../features/scoring/presentation/screens/scorecard_screen.dart';
import '../../features/teams/presentation/screens/team_detail_screen.dart';
import '../../features/teams/presentation/screens/team_form_screen.dart';
import '../../features/teams/presentation/screens/global_teams_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_detail_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_form_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_list_screen.dart';
import '../../features/tournaments/presentation/screens/points_table_screen.dart';
import '../../features/players/presentation/screens/player_stats_screen.dart';
import '../../features/players/presentation/screens/player_form_screen.dart';
import '../../features/players/presentation/screens/global_players_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/scoring/presentation/screens/match_summary_screen.dart';
import '../../features/matches/presentation/screens/global_matches_screen.dart';
import '../../features/dashboard/presentation/screens/stats_overview_screen.dart';
import '../constants/app_constants.dart';

final splashCompleteProvider = StateNotifierProvider<SplashNotifier, bool>((ref) {
  return SplashNotifier();
});

class SplashNotifier extends StateNotifier<bool> {
  SplashNotifier() : super(false) {
    _startTimer();
  }

  void _startTimer() async {
    await Future.delayed(const Duration(seconds: 4));
    state = true;
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, __) {
    refreshNotifier.notify();
  });
  ref.listen<bool>(splashCompleteProvider, (_, __) {
    refreshNotifier.notify();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final splashDone = ref.read(splashCompleteProvider);
      final loc = state.matchedLocation;

      // 1. Hold on splash screen for at least 2 seconds
      if (!splashDone) {
        return loc == '/splash' ? null : '/splash';
      }

      final authAsync = ref.read(authStateProvider);
      final onAuthRoute = loc == '/login' || loc == '/signup';
      if (authAsync.isLoading && !authAsync.hasValue) {
        return loc == '/splash' ? null : '/splash';
      }
      final user = authAsync.value;
      if (user == null) return onAuthRoute ? null : '/login';
      final isSuperAdmin = user.role == UserRole.superAdmin;
      final isAdmin = user.role.isAdmin;
      final isScorer = user.role == UserRole.scorer;
      final home = isSuperAdmin ? '/admin' : '/member';
      if (loc == '/splash' || onAuthRoute) return home;

      final superAdminOnly = loc.startsWith('/admin') || loc.startsWith('/members');
      if (superAdminOnly && !isSuperAdmin) return home;

      final matchScoringOnly = loc.endsWith('/scoring') || loc.startsWith('/matches/new');
      if (matchScoringOnly && !isAdmin && !isScorer) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                redirect: (context, state) {
                  final user = ref.read(authStateProvider).value;
                  if (user != null && user.role == UserRole.superAdmin) return '/admin';
                  return '/member';
                },
                builder: (_, __) => const SizedBox(),
              ),
              GoRoute(path: '/member', builder: (_, __) => const MemberDashboard()),
              GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
            ],
          ),
          // Branch 1: Matches
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/matches-list', builder: (_, __) => const GlobalMatchesScreen()),
            ],
          ),
          // Branch 2: Live
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/live-matches', builder: (_, __) => const LiveMatchesScreen()),
            ],
          ),
      // Branch 3: Stats
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/stats', builder: (_, __) => const StatsOverviewScreen()),
        ],
      ),
      // Branch 4: Profile
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ]),
    
    // Other top-level routes
    GoRoute(
      path: '/tournaments',
      builder: (_, __) => const TournamentListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const TournamentFormScreen(),
        ),
        GoRoute(
          path: ':tid',
          builder: (_, s) => TournamentDetailScreen(
            tournamentId: s.pathParameters['tid']!,
          ),
          routes: [
            GoRoute(
              path: 'points-table',
              builder: (_, s) => PointsTableScreen(
                tournamentId: s.pathParameters['tid']!,
              ),
            ),
            GoRoute(
              path: 'edit',
              builder: (_, s) => TournamentFormScreen(
                tournamentId: s.pathParameters['tid']!,
              ),
            ),
            GoRoute(
              path: 'teams/new',
              builder: (_, s) => TeamFormScreen(
                tournamentId: s.pathParameters['tid']!,
              ),
            ),
            GoRoute(
              path: 'teams/:teamId',
              builder: (_, s) => TeamDetailScreen(
                tournamentId: s.pathParameters['tid']!,
                teamId: s.pathParameters['teamId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, s) => TeamFormScreen(
                    tournamentId: s.pathParameters['tid']!,
                    teamId: s.pathParameters['teamId']!,
                  ),
                ),
                GoRoute(
                  path: 'players/new',
                  builder: (_, s) => PlayerFormScreen(
                    tournamentId: s.pathParameters['tid']!,
                    teamId: s.pathParameters['teamId']!,
                  ),
                ),
                GoRoute(
                  path: 'players/:playerId/edit',
                  builder: (_, s) => PlayerFormScreen(
                    tournamentId: s.pathParameters['tid']!,
                    teamId: s.pathParameters['teamId']!,
                    playerId: s.pathParameters['playerId']!,
                  ),
                ),
                GoRoute(
                  path: 'players/:playerId/stats',
                  builder: (_, s) => PlayerStatsScreen(
                    tournamentId: s.pathParameters['tid']!,
                    teamId: s.pathParameters['teamId']!,
                    playerId: s.pathParameters['playerId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'matches/new',
              builder: (_, s) => MatchFormScreen(
                tournamentId: s.pathParameters['tid']!,
              ),
            ),
            GoRoute(
              path: 'matches/:mid',
              builder: (_, s) => MatchDetailScreen(
                tournamentId: s.pathParameters['tid']!,
                matchId: s.pathParameters['mid']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, s) => MatchFormScreen(
                    tournamentId: s.pathParameters['tid']!,
                    matchId: s.pathParameters['mid']!,
                  ),
                ),
                GoRoute(
                  path: 'squads',
                  builder: (_, s) => MatchSquadsScreen(
                    tournamentId: s.pathParameters['tid']!,
                    matchId: s.pathParameters['mid']!,
                  ),
                ),
                GoRoute(
                  path: 'summary',
                  builder: (_, s) => MatchSummaryScreen(
                    tournamentId: s.pathParameters['tid']!,
                    matchId: s.pathParameters['mid']!,
                  ),
                ),
                GoRoute(
                  path: 'scoring',
                  builder: (_, s) => LiveScorerScreen(
                    tournamentId: s.pathParameters['tid']!,
                    matchId: s.pathParameters['mid']!,
                  ),
                ),
                GoRoute(
                  path: 'live',
                  builder: (_, s) => LiveViewerScreen(
                    tournamentId: s.pathParameters['tid']!,
                    matchId: s.pathParameters['mid']!,
                  ),
                ),
                GoRoute(
                  path: 'scorecard',
                  builder: (_, s) => ScorecardScreen(
                    tournamentId: s.pathParameters['tid']!,
                    matchId: s.pathParameters['mid']!,
                  ),
                ),
                GoRoute(
                  path: 'charts',
                  builder: (_, s) => ChartsScreen(
                    tournamentId: s.pathParameters['tid']!,
                    matchId: s.pathParameters['mid']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/teams',
      builder: (_, __) => const GlobalTeamsScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const TeamFormScreen(),
        ),
        GoRoute(
          path: ':teamId',
          builder: (_, s) => TeamDetailScreen(
            teamId: s.pathParameters['teamId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, s) => TeamFormScreen(
                teamId: s.pathParameters['teamId']!,
              ),
            ),
            GoRoute(
              path: 'players/new',
              builder: (_, s) => PlayerFormScreen(
                tournamentId: 'global',
                teamId: s.pathParameters['teamId']!,
              ),
            ),
            GoRoute(
              path: 'players/:playerId/edit',
              builder: (_, s) => PlayerFormScreen(
                tournamentId: 'global',
                teamId: s.pathParameters['teamId']!,
                playerId: s.pathParameters['playerId']!,
              ),
            ),
            GoRoute(
              path: 'players/:playerId/stats',
              builder: (_, s) => PlayerStatsScreen(
                tournamentId: 'global',
                teamId: s.pathParameters['teamId']!,
                playerId: s.pathParameters['playerId']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/players',
      builder: (_, __) => const GlobalPlayersScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const PlayerFormScreen(),
        ),
        GoRoute(
          path: ':playerId/edit',
          builder: (_, s) => PlayerFormScreen(
            playerId: s.pathParameters['playerId'],
          ),
        ),
        GoRoute(
          path: ':playerId/stats',
          builder: (_, s) => PlayerStatsScreen(
            tournamentId: 'global',
            teamId: 'global',
            playerId: s.pathParameters['playerId']!,
          ),
        ),
      ],
    ),
    GoRoute(path: '/matches/new', builder: (_, __) => const MatchFormScreen()),
    GoRoute(
      path: '/members',
      builder: (_, s) => MemberManagementScreen(
        initialFilter: s.uri.queryParameters['filter'] ?? 'all',
      ),
    ),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}'))),
  );
});
