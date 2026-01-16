import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FeedShimmer extends StatelessWidget {
  const FeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[900]!,
                      highlightColor: Colors.grey[800]!,
                      child: const CircleAvatar(radius: 20),
                    ),
                    const SizedBox(width: 12),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[900]!,
                      highlightColor: Colors.grey[800]!,
                      child: Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Image Shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[800]!,
                child: Container(
                  width: double.infinity,
                  height: 400, // Aspect ratio roughly 4:5 or 1:1
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              // Actions Shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[900]!,
                          highlightColor: Colors.grey[800]!,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Caption Shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[900]!,
                      highlightColor: Colors.grey[800]!,
                      child: Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[900]!,
                      highlightColor: Colors.grey[800]!,
                      child: Container(
                        width: 250,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
