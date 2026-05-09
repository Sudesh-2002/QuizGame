import 'package:flutter/material.dart';
import '../models/category_model.dart';

final List<CategoryModel> appCategories = [
  CategoryModel(
    id: 'general',
    name: 'General Knowledge',
    emoji: '🌍',
    color: const Color(0xFF6C63FF),
    darkColor: const Color(0xFF4B44CC),
  ),
  CategoryModel(
    id: 'science',
    name: 'Science & Nature',
    emoji: '🔬',
    color: const Color(0xFF00BCD4),
    darkColor: const Color(0xFF0097A7),
  ),
  CategoryModel(
    id: 'history',
    name: 'History',
    emoji: '🏛️',
    color: const Color(0xFFFF9800),
    darkColor: const Color(0xFFF57C00),
  ),
  CategoryModel(
    id: 'sports',
    name: 'Sports',
    emoji: '⚽',
    color: const Color(0xFF4CAF50),
    darkColor: const Color(0xFF388E3C),
  ),
  CategoryModel(
    id: 'movies',
    name: 'Movies & TV',
    emoji: '🎬',
    color: const Color(0xFFE91E63),
    darkColor: const Color(0xFFC2185B),
  ),
  CategoryModel(
    id: 'music',
    name: 'Music',
    emoji: '🎵',
    color: const Color(0xFF9C27B0),
    darkColor: const Color(0xFF7B1FA2),
  ),
  CategoryModel(
    id: 'technology',
    name: 'Technology',
    emoji: '💻',
    color: const Color(0xFF2196F3),
    darkColor: const Color(0xFF1976D2),
  ),
  CategoryModel(
    id: 'food',
    name: 'Food & Cooking',
    emoji: '🍕',
    color: const Color(0xFFFF5722),
    darkColor: const Color(0xFFE64A19),
  ),
  CategoryModel(
    id: 'geography',
    name: 'Geography',
    emoji: '🗺️',
    color: const Color(0xFF009688),
    darkColor: const Color(0xFF00796B),
  ),
  CategoryModel(
    id: 'anime',
    name: 'Anime & Manga',
    emoji: '🎌',
    color: const Color(0xFFFF4081),
    darkColor: const Color(0xFFF50057),
  ),
];