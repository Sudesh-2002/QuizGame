import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final Color darkColor;
  final int totalQuestions;
  final int questionsPlayed;

  CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.darkColor,
    this.totalQuestions = 0,
    this.questionsPlayed = 0,
  });

  double get progressPercent =>
      totalQuestions == 0 ? 0 : questionsPlayed / totalQuestions;
}