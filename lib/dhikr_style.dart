import 'package:flutter/material.dart';

Color accentFor(String id) {
  return switch (id) {
    'istighfar' => const Color(0xFF097AFF),
    'hamd' => const Color(0xFF1F9D55),
    'subhan' => const Color(0xFFF5A524),
    'akbar' => const Color(0xFF7C5CFC),
    'salawat' => const Color(0xFF0EA5A0),
    _ => const Color(0xFF097AFF),
  };
}

IconData iconFor(String id) {
  return switch (id) {
    'istighfar' => Icons.favorite_rounded,
    'hamd' => Icons.wb_sunny_rounded,
    'subhan' => Icons.auto_awesome_rounded,
    'akbar' => Icons.stars_rounded,
    'salawat' => Icons.mosque_rounded,
    _ => Icons.add_rounded,
  };
}
