import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arabic_font/arabic_font.dart';
import '../providers/ahadith_slider_provider.dart';
import '../screens/hadith_details.dart';
class AhadithScreen extends ConsumerWidget {
  final int chapterId;
  final int? hadithId;
  const AhadithScreen({Key? key, required this.chapterId, this.hadithId,}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hadithProvider);
    final notifier = ref.read(hadithProvider.notifier);
    final pageController = ref.read(pageControllerProvider);

    if (state.chapterId != chapterId || state.hadiths.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadHadiths(chapterId);
      });
    }

    return Scaffold(
      
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildContent(context, state, notifier, pageController),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HadithState state,
    HadithNotifier notifier,
    PageController pageController,
  ) {
    if (state.isLoading && state.hadiths.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage!,
              style: ArabicTextStyle(
                arabicFont: ArabicFont.reemKufi,
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.refresh(),
              child: Text(
                'إعادة المحاولة',
                style: ArabicTextStyle(
                  arabicFont: ArabicFont.reemKufi,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.hadiths.isEmpty) {
      return Center(
        child: Text(
          'لا توجد أحاديث متاحة',
          style: ArabicTextStyle(
            arabicFont: ArabicFont.reemKufi,
            fontSize: 18,
          ),
        ),
      );
    }

    return Stack(
      children: [
        SafeArea(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: notifier.handlePageChanged,
            itemCount: state.hadiths.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => notifier.startDrag(),
                onHorizontalDragUpdate: (details) {
                  notifier.updateDrag(details.primaryDelta!);
                  final newPage = (pageController.page ?? state.currentIndex.toDouble()) - 
                      (details.primaryDelta! / MediaQuery.of(context).size.width);
                  pageController.jumpToPage(newPage.clamp(0, state.hadiths.length - 1).round());
                },
                onHorizontalDragEnd: (details) => notifier.endDrag(details.primaryVelocity!, context),
                child: Transform.translate(
                  offset: Offset(state.isDragging ? state.dragOffset * 0.5 : 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: HadithDetails(
                     
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: _buildPageIndicator(state),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(HadithState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        state.hadiths.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == state.currentIndex
                ? const Color(0xffe6a345)
                : const Color.fromRGBO(158, 158, 158, .5),
          ),
        ),
      ),
    );
  }
}

