import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/my_profile_provider.dart';
import '../models/meetup.dart';
import '../repository/meetups_repository.dart';

final meetupsRepositoryProvider = Provider<MeetupsRepository>((ref) {
  return MeetupsRepository(ref.watch(firestoreProvider));
});

final upcomingMeetupsProvider = StreamProvider<List<Meetup>>((ref) {
  return ref.watch(meetupsRepositoryProvider).watchUpcoming();
});

final meetupByIdProvider =
    StreamProvider.family<Meetup?, String>((ref, meetupId) {
  return ref.watch(meetupsRepositoryProvider).watchMeetup(meetupId);
});
