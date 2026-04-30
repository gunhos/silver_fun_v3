import '../../l10n/app_localizations.dart';

/// Maps a canonical English interest value (as stored in Firestore via
/// `kInterestPool`) to its localized display label.
///
/// Unknown values fall back to the raw input — this preserves backwards
/// compatibility for any profile whose stored interest list contains a value
/// no longer in the current pool.
extension InterestLabel on AppLocalizations {
  String localizedInterest(String value) {
    switch (value) {
      case 'Gardening':
        return interestGardening;
      case 'Walking':
        return interestWalking;
      case 'Cooking':
        return interestCooking;
      case 'Baking':
        return interestBaking;
      case 'Coffee':
        return interestCoffee;
      case 'Travel':
        return interestTravel;
      case 'Reading':
        return interestReading;
      case 'Photography':
        return interestPhotography;
      case 'Yoga':
        return interestYoga;
      case 'Bird watching':
        return interestBirdWatching;
      case 'Crafts':
        return interestCrafts;
      case 'Knitting':
        return interestKnitting;
      case 'Board games':
        return interestBoardGames;
      case 'Cards & bridge':
        return interestCardsAndBridge;
      case 'Movies':
        return interestMovies;
      case 'Theatre':
        return interestTheatre;
      case 'Art':
        return interestArt;
      case 'Live music':
        return interestLiveMusic;
      case 'Dancing':
        return interestDancing;
      case 'Volunteering':
        return interestVolunteering;
      case 'Grandkids':
        return interestGrandkids;
      case 'Dogs':
        return interestDogs;
      case 'Cats':
        return interestCats;
      case 'Plants':
        return interestPlants;
      default:
        return value;
    }
  }
}
