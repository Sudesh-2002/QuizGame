import '../models/question_model.dart';

final Map<String, List<QuestionModel>> sampleQuestions = {
  'general': [
    QuestionModel(
      id: 'g1',
      question: 'What is the capital of France?',
      options: ['Berlin', 'Madrid', 'Paris', 'Rome'],
      correctIndex: 2,
      category: 'general',
      difficulty: 'Easy',
      explanation: 'Paris has been the capital of France since 987 AD.',
    ),
    QuestionModel(
      id: 'g2',
      question: 'How many continents are there on Earth?',
      options: ['5', '6', '7', '8'],
      correctIndex: 2,
      category: 'general',
      difficulty: 'Easy',
      explanation: 'The 7 continents are Africa, Antarctica, Asia, Australia, Europe, North America, and South America.',
    ),
    QuestionModel(
      id: 'g3',
      question: 'What is the largest ocean on Earth?',
      options: ['Atlantic', 'Indian', 'Arctic', 'Pacific'],
      correctIndex: 3,
      category: 'general',
      difficulty: 'Easy',
      explanation: 'The Pacific Ocean covers more than 30% of the Earth\'s surface.',
    ),
    QuestionModel(
      id: 'g4',
      question: 'Which planet is known as the Red Planet?',
      options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      correctIndex: 1,
      category: 'general',
      difficulty: 'Easy',
      explanation: 'Mars appears red due to iron oxide (rust) on its surface.',
    ),
    QuestionModel(
      id: 'g5',
      question: 'What is the hardest natural substance on Earth?',
      options: ['Gold', 'Iron', 'Diamond', 'Platinum'],
      correctIndex: 2,
      category: 'general',
      difficulty: 'Medium',
      explanation: 'Diamond scores 10 on the Mohs hardness scale.',
    ),
    QuestionModel(
      id: 'g6',
      question: 'Who painted the Mona Lisa?',
      options: ['Van Gogh', 'Picasso', 'Michelangelo', 'Leonardo da Vinci'],
      correctIndex: 3,
      category: 'general',
      difficulty: 'Easy',
      explanation: 'Leonardo da Vinci painted the Mona Lisa between 1503 and 1519.',
    ),
    QuestionModel(
      id: 'g7',
      question: 'How many bones are in the adult human body?',
      options: ['196', '206', '216', '226'],
      correctIndex: 1,
      category: 'general',
      difficulty: 'Medium',
      explanation: 'An adult human body has 206 bones.',
    ),
    QuestionModel(
      id: 'g8',
      question: 'What is the chemical symbol for Gold?',
      options: ['Go', 'Gd', 'Au', 'Ag'],
      correctIndex: 2,
      category: 'general',
      difficulty: 'Medium',
      explanation: 'Au comes from the Latin word "Aurum" meaning gold.',
    ),
    QuestionModel(
      id: 'g9',
      question: 'Which country has the largest population?',
      options: ['USA', 'India', 'China', 'Russia'],
      correctIndex: 1,
      category: 'general',
      difficulty: 'Easy',
      explanation: 'India surpassed China as the most populous country in 2023.',
    ),
    QuestionModel(
      id: 'g10',
      question: 'What is the speed of light?',
      options: ['299,792 km/s', '199,792 km/s', '399,792 km/s', '499,792 km/s'],
      correctIndex: 0,
      category: 'general',
      difficulty: 'Hard',
      explanation: 'The speed of light in a vacuum is approximately 299,792 km/s.',
    ),
  ],

  'science': [
    QuestionModel(
      id: 's1',
      question: 'What is the chemical formula for water?',
      options: ['HO', 'H2O', 'H3O', 'HO2'],
      correctIndex: 1,
      category: 'science',
      difficulty: 'Easy',
      explanation: 'Water consists of two hydrogen atoms bonded to one oxygen atom.',
    ),
    QuestionModel(
      id: 's2',
      question: 'What gas do plants absorb from the atmosphere?',
      options: ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen'],
      correctIndex: 2,
      category: 'science',
      difficulty: 'Easy',
      explanation: 'Plants absorb CO2 during photosynthesis to produce glucose.',
    ),
    QuestionModel(
      id: 's3',
      question: 'What is the powerhouse of the cell?',
      options: ['Nucleus', 'Ribosome', 'Mitochondria', 'Chloroplast'],
      correctIndex: 2,
      category: 'science',
      difficulty: 'Easy',
      explanation: 'Mitochondria produce ATP through cellular respiration.',
    ),
    QuestionModel(
      id: 's4',
      question: 'What is the atomic number of Carbon?',
      options: ['4', '6', '8', '12'],
      correctIndex: 1,
      category: 'science',
      difficulty: 'Medium',
      explanation: 'Carbon has 6 protons, giving it an atomic number of 6.',
    ),
    QuestionModel(
      id: 's5',
      question: 'Which planet has the most moons?',
      options: ['Jupiter', 'Saturn', 'Uranus', 'Neptune'],
      correctIndex: 1,
      category: 'science',
      difficulty: 'Hard',
      explanation: 'Saturn has 146 confirmed moons as of 2023.',
    ),
  ],

  'technology': [
    QuestionModel(
      id: 't1',
      question: 'What does CPU stand for?',
      options: [
        'Central Processing Unit',
        'Computer Personal Unit',
        'Central Program Utility',
        'Core Processing Unit'
      ],
      correctIndex: 0,
      category: 'technology',
      difficulty: 'Easy',
      explanation: 'The CPU is the primary component that executes instructions.',
    ),
    QuestionModel(
      id: 't2',
      question: 'Who founded Apple Inc.?',
      options: [
        'Bill Gates',
        'Steve Jobs',
        'Elon Musk',
        'Mark Zuckerberg'
      ],
      correctIndex: 1,
      category: 'technology',
      difficulty: 'Easy',
      explanation: 'Steve Jobs co-founded Apple with Steve Wozniak and Ronald Wayne in 1976.',
    ),
    QuestionModel(
      id: 't3',
      question: 'What does HTML stand for?',
      options: [
        'Hyper Text Markup Language',
        'High Text Machine Language',
        'Hyper Transfer Markup Language',
        'Home Tool Markup Language'
      ],
      correctIndex: 0,
      category: 'technology',
      difficulty: 'Easy',
      explanation: 'HTML is the standard markup language for web pages.',
    ),
    QuestionModel(
      id: 't4',
      question: 'What programming language is Flutter built on?',
      options: ['Java', 'Kotlin', 'Dart', 'Swift'],
      correctIndex: 2,
      category: 'technology',
      difficulty: 'Medium',
      explanation: 'Flutter uses the Dart programming language developed by Google.',
    ),
    QuestionModel(
      id: 't5',
      question: 'What does GPU stand for?',
      options: [
        'General Processing Unit',
        'Graphics Processing Unit',
        'Global Program Utility',
        'Graphics Program Unit'
      ],
      correctIndex: 1,
      category: 'technology',
      difficulty: 'Easy',
      explanation: 'GPU handles rendering graphics and parallel computing tasks.',
    ),
  ],
};

// Get questions for a category
List<QuestionModel> getQuestionsForCategory(
  String categoryId,
  int count,
  String difficulty,
) {
  final all = sampleQuestions[categoryId] ?? sampleQuestions['general']!;
  final filtered = difficulty == 'All'
      ? all
      : all.where((q) => q.difficulty == difficulty).toList();

  final list = filtered.isEmpty ? all : filtered;
  list.shuffle();
  return list.take(count).toList();
}