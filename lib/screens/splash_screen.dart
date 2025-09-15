import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../screens/home_screen.dart';
import '../main.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final bool showHadithOnLaunch;
  final bool isStartupLaunch;
  
  const SplashScreen({
    super.key,
    this.showHadithOnLaunch = false,
    this.isStartupLaunch = false,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _controller.forward();
    
    // Wait for initialization to complete
    await ref.read(initializationProvider.future);
    
    // Additional delay like in the old version
    await Future.delayed(const Duration(seconds: 4));
    
    if (mounted) {
      // If this is a startup launch, don't show the main window immediately
      if (widget.isStartupLaunch) {
        debugPrint('Startup launch - keeping window hidden');
        if (Platform.isWindows) {
          await windowManager.hide();
          await windowManager.setSkipTaskbar(true);
        }
        // Still navigate to HomeScreen but window remains hidden
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              showHadithDetails: widget.showHadithOnLaunch,
            ),
          ),
        );
      } else {
        // Normal launch - show window and navigate
        if (Platform.isWindows) {
          await windowManager.show();
          await windowManager.setSkipTaskbar(false);
          await windowManager.focus();
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              showHadithDetails: widget.showHadithOnLaunch,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          TextApp.appBackgroundWidgetForSplashScreen,
          Container(color: const Color.fromRGBO(0, 0, 0, 0.2)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;

                final baseFontSize =
                    isLandscape
                        ? constraints.maxHeight * 0.10
                        : constraints.maxWidth * 0.11;
                final subFontSize =
                    isLandscape
                        ? constraints.maxHeight * 0.08
                        : constraints.maxWidth * 0.095;

                final topSpacing =
                    isLandscape ? constraints.maxHeight * 0.05 : 70.0;
                final bottomSpacing =
                    isLandscape ? constraints.maxHeight * 0.1 : 200.0;

                return SingleChildScrollView(
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(height: topSpacing),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "موسوعة",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: baseFontSize,
                                        color: const Color(0xffecbd79),
                                        shadows: [
                                          Shadow(
                                            blurRadius: isLandscape ? 8 : 10,
                                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "أحاديث",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: baseFontSize,
                                        color: const Color(0xffecbd79),
                                        shadows: [
                                          Shadow(
                                            blurRadius: isLandscape ? 8 : 10,
                                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "ألزكاة",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: subFontSize,
                                        color: const Color(0xffecbd79),
                                        shadows: [
                                          Shadow(
                                            blurRadius: isLandscape ? 8 : 10,
                                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: TextApp.drSamyKhalilName,
                            );
                          },
                        ),
                        SizedBox(height: bottomSpacing),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}