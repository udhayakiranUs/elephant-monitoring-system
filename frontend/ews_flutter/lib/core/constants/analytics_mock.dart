// GENERATED from the HTML prototype's Excel data (Jan 2024 - Mar 2026).
// Replace with GET /analytics once the backend exists.
import '../../models/range_model.dart';

class AnalyticsMock {
  AnalyticsMock._();

  static const List<String> months = ['Jan-2024', 'Feb-2024', 'Mar-2024', 'Apr-2024', 'May-2024', 'Jun-2024', 'Jul-2024', 'Aug-2024', 'Sep-2024', 'Oct-2024', 'Nov-2024', 'Dec-2024', 'Jan-2025', 'Feb-2025', 'Mar-2025', 'Apr-2025', 'May-2025', 'Jun-2025', 'Jul-2025', 'Aug-2025', 'Sep-2025', 'Oct-2025', 'Nov-2025', 'Dec-2025', 'Jan-2026', 'Feb-2026', 'Mar-2026'];
  static const List<int> monthlyElephants = [1088, 902, 550, 585, 670, 529, 538, 372, 774, 1226, 1449, 1241, 1229, 650, 915, 851, 651, 406, 327, 239, 425, 761, 1160, 1279, 696, 247, 313];
  static const List<int> monthlyIncidents = [624, 613, 354, 343, 374, 331, 365, 270, 363, 464, 517, 528, 610, 349, 438, 392, 344, 202, 201, 155, 186, 331, 394, 463, 296, 205, 211];

  static const List<RangeStat> rangeStats = [
    RangeStat(range: 'Bolampatty', lm: 891, mg: 771, fg: 123, fc: 300, sf: 26, ug: 67, mk: 0, elephants: 2170, incidents: 1349),
    RangeStat(range: 'Coimbatore', lm: 1375, mg: 714, fg: 624, fc: 1878, sf: 82, ug: 0, mk: 23, elephants: 4654, incidents: 2012),
    RangeStat(range: 'Karamadai', lm: 594, mg: 70, fg: 145, fc: 361, sf: 112, ug: 1, mk: 1, elephants: 1279, incidents: 659),
    RangeStat(range: 'Madukkarai', lm: 338, mg: 203, fg: 81, fc: 164, sf: 8, ug: 41, mk: 1, elephants: 828, incidents: 449),
    RangeStat(range: 'Mettupalayam', lm: 1910, mg: 733, fg: 238, fc: 1007, sf: 52, ug: 1, mk: 21, elephants: 3964, incidents: 2289),
    RangeStat(range: 'Periyanaickenpalayam', lm: 1014, mg: 435, fg: 373, fc: 2423, sf: 21, ug: 292, mk: 10, elephants: 4588, incidents: 1600),
    RangeStat(range: 'Sirumugai', lm: 968, mg: 1049, fg: 61, fc: 326, sf: 31, ug: 6, mk: 0, elephants: 2590, incidents: 1565),
  ];

  /// Range x month elephants pivot (27 values each).
  static const Map<String, List<int>> pivot = {
    'Bolampatty': [79,150,78,102,59,64,77,82,115,179,95,103,118,60,50,66,81,123,77,79,30,54,9,122,76,11,31],
    'Coimbatore': [99,100,49,49,38,73,62,84,261,329,412,199,287,75,116,181,167,85,133,71,317,491,281,330,219,56,90],
    'Karamadai': [17,12,15,23,25,22,26,7,10,39,202,131,81,56,43,82,54,22,1,28,6,47,137,93,48,25,27],
    'Madukkarai': [33,35,23,12,27,0,15,72,3,28,4,34,77,73,36,7,39,11,18,0,45,4,1,74,118,29,10],
    'Mettupalayam': [194,126,110,143,324,237,197,88,153,165,119,133,329,176,371,219,131,51,27,30,11,99,163,172,0,98,98],
    'Periyanaickenpalayam': [409,223,172,189,123,72,107,13,130,250,337,331,228,171,251,173,116,103,71,19,8,1,464,393,173,21,40],
    'Sirumugai': [257,256,103,67,74,61,54,26,102,236,280,310,109,39,48,123,63,11,0,12,8,65,105,95,62,7,17],
  };

  static const List<({int year, int elephants, int incidents})> yearly = [
    (year: 2024, elephants: 9924, incidents: 5146),
    (year: 2025, elephants: 8893, incidents: 4065),
    (year: 2026, elephants: 1256, incidents: 712),
  ];

  static const List<({String month, int elephants})> peakMonths = [
    (month: 'Nov-2024', elephants: 1449),
    (month: 'Dec-2025', elephants: 1279),
    (month: 'Dec-2024', elephants: 1241),
    (month: 'Jan-2025', elephants: 1229),
    (month: 'Oct-2024', elephants: 1226),
  ];

  static const int totalRecords = 189;
  static const int allTimeRecorded = 20081;
  static const int totalIncidents = 9931;
}
