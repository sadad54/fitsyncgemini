// lib/constants/app_data.dart
import 'package:fitsyncgemini/models/clothing_item.dart';
import 'package:fitsyncgemini/models/outfit.dart';
import 'package:fitsyncgemini/models/onboarding_data.dart';
import 'package:fitsyncgemini/models/quiz_question.dart';

const List<OnboardingData> onboardingScreens = [
  OnboardingData(
    title: 'Smart Wardrobe Management',
    subtitle: 'Upload your clothes and let AI organize them automatically',
    description:
        'Take photos of your clothing items and watch as our AI categorizes, tags, and organizes your digital closet.',
    illustration: 'smartWardrobe',
  ),
  OnboardingData(
    title: 'AI-Powered Style Suggestions',
    subtitle: 'Get personalized outfit recommendations daily',
    description:
        'Our AI learns your style preferences and suggests perfect outfit combinations from your own closet.',
    illustration: 'aiSuggestions',
  ),
  OnboardingData(
    title: 'Weather-Smart Styling',
    subtitle: 'Dress perfectly for any forecast',
    description:
        'FitSync checks the weather for you and suggests outfits that are not only stylish but also comfortable for the day\'s conditions.',
    illustration: 'weatherSmart',
  ),
  OnboardingData(
    title: 'Share Your Style',
    subtitle: 'Connect with friends and share your favorite looks',
    description:
        'Get feedback from friends, share your outfits on social media, and discover inspiration from the FitSync community.',
    illustration: 'socialShare',
  ),
];

const List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    question: 'What\'s your ideal weekend outfit?',
    options: [
      'Comfortable jeans and a cozy sweater',
      'A flowy dress with layered accessories',
      'Tailored pants and a crisp button-down',
      'Athleisure with trendy sneakers',
    ],
  ),
  QuizQuestion(
    question: 'Which color palette do you gravitate towards?',
    options: [
      'Neutral tones (black, white, beige)',
      'Earthy and warm colors (brown, olive, rust)',
      'Bright and bold hues (red, cobalt blue, hot pink)',
      'Pastels and soft shades (lavender, mint, blush)',
    ],
  ),
  QuizQuestion(
    question: 'Pick a shoe style you can\'t live without:',
    options: [
      'Classic leather loafers',
      'Strappy sandals or ankle boots',
      'Sleek, minimalist sneakers',
      'Statement heels or chunky platforms',
    ],
  ),
  QuizQuestion(
    question: 'How would you describe your approach to accessories?',
    options: [
      'Less is more - a single, timeless piece',
      'Layered and eclectic necklaces and bracelets',
      'Bold, architectural jewelry',
      'I prefer no accessories at all',
    ],
  ),
  QuizQuestion(
    question: 'Your favorite type of print is:',
    options: [
      'I prefer solid colors',
      'Floral or paisley',
      'Geometric or abstract',
      'Animal print or graphic tees',
    ],
  ),
];

// Sample data for demonstration
List<ClothingItem> sampleCloset = [
  ClothingItem(
    id: '1',
    name: 'White T-Shirt',
    category: 'Tops',
    image: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=400',
    colors: ['White'],
    subCategory: '',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
  ),
  ClothingItem(
    id: '2',
    name: 'Blue Denim Jeans',
    category: 'Bottoms',
    image: 'https://images.unsplash.com/photo-1602293589914-9e19a782a0e5?w=400',
    colors: ['Blue'],
    subCategory: '',
    createdAt: DateTime(2024, 1, 3),
    updatedAt: DateTime(2024, 1, 4),
  ),
  ClothingItem(
    id: '3',
    name: 'Black Leather Jacket',
    category: 'Outerwear',
    image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
    colors: ['Black'],
    subCategory: '',
    createdAt: DateTime(2024, 1, 5),
    updatedAt: DateTime(2024, 1, 6),
  ),
  ClothingItem(
    id: '4',
    name: 'Floral Sundress',
    category: 'Dresses',
    image: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400',
    colors: ['Pink', 'Green', 'White'],
    subCategory: '',
    createdAt: DateTime(2024, 1, 7),
    updatedAt: DateTime(2024, 1, 8),
  ),
  ClothingItem(
    id: '5',
    name: 'White Sneakers',
    category: 'Shoes',
    image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
    colors: ['White'],
    subCategory: '',
    createdAt: DateTime(2024, 1, 9),
    updatedAt: DateTime(2024, 1, 10),
  ),
  ClothingItem(
    id: '6',
    name: 'Beige Trench Coat',
    category: 'Outerwear',
    image: 'https://images.unsplash.com/photo-1572455024142-2d12aa5f5104?w=400',
    colors: ['Beige'],
    subCategory: '',
    createdAt: DateTime(2024, 1, 11),
    updatedAt: DateTime(2024, 1, 12),
  ),
];

final List<Outfit> sampleOutfits = [
  Outfit(
    id: 'outfit1',
    name: 'Casual Weekend',
    occasion: 'a casual day out',
    itemIds: ['1', '2', '5'],
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 2, 2),
  ),
  Outfit(
    id: 'outfit2',
    name: 'Edgy Night Out',
    occasion: 'a night out',
    itemIds: ['3', '2', '5'],
    createdAt: DateTime(2024, 2, 3),
    updatedAt: DateTime(2024, 2, 4),
  ),
];
