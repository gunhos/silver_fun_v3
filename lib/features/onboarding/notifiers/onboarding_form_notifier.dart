import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingFormState {
  final String name;
  final int? age;
  final String bio;
  final String photoUrl;
  final List<String> interests;

  const OnboardingFormState({
    this.name = '',
    this.age,
    this.bio = '',
    this.photoUrl = '',
    this.interests = const <String>[],
  });

  bool get isNameAgeValid {
    final n = name.trim();
    final a = age;
    return n.length >= 2 && a != null && a >= 18 && a < 120;
  }

  bool get isPhotoValid => photoUrl.isNotEmpty;

  bool get isBioValid {
    final b = bio.trim();
    return b.length >= 10 && b.length <= 180;
  }

  bool get isInterestsValid =>
      interests.length >= 3 && interests.length <= 6;

  OnboardingFormState copyWith({
    String? name,
    Object? age = _sentinel,
    String? bio,
    String? photoUrl,
    List<String>? interests,
  }) {
    return OnboardingFormState(
      name: name ?? this.name,
      age: identical(age, _sentinel) ? this.age : age as int?,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      interests: interests ?? this.interests,
    );
  }

  static const Object _sentinel = Object();
}

class OnboardingFormNotifier extends Notifier<OnboardingFormState> {
  @override
  OnboardingFormState build() {
    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?.trim() ?? '';
    final firstName = display.isEmpty ? '' : display.split(' ').first;
    return OnboardingFormState(name: firstName);
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAge(int? age) {
    state = state.copyWith(age: age);
  }

  void updateBio(String bio) {
    state = state.copyWith(bio: bio);
  }

  void updatePhotoUrl(String url) {
    state = state.copyWith(photoUrl: url);
  }

  void toggleInterest(String tag) {
    final current = List<String>.from(state.interests);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      if (current.length >= 6) return;
      current.add(tag);
    }
    state = state.copyWith(interests: current);
  }

  void reset() {
    state = const OnboardingFormState();
  }
}

final onboardingFormProvider =
    NotifierProvider<OnboardingFormNotifier, OnboardingFormState>(
  OnboardingFormNotifier.new,
);
