import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/app_user.dart';
import '../../data/repositories/member_repository.dart';

final memberRepositoryProvider = Provider((_) => MemberRepository());
final memberListProvider = StreamProvider<List<AppUser>>((ref) =>
  ref.watch(memberRepositoryProvider).watchAll());
