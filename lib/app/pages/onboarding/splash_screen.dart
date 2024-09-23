import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:roomie_tasks/app/services/onboarding_service.dart';
import 'package:roomie_tasks/config/routes/routes.dart';
import 'package:roomie_tasks/dependency_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Roomie Tasks',
      description:
          'Simplify your shared living experience with easy task management.',
      image: 'assets/images/welcome.svg',
    ),
    OnboardingPage(
      title: 'Create and Assign Tasks',
      description: 'Easily create tasks and assign them to roommates.',
      image: 'assets/images/create_tasks.svg',
    ),
    OnboardingPage(
      title: 'Track Progress',
      description:
          'Monitor task completion and maintain a harmonious living space.',
      image: 'assets/images/track_progress.svg',
    ),
  ];

  late final OnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = sl<OnboardingService>();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final isCompleted = await _onboardingService.isOnboardingCompleted();
    if (isCompleted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    context.go(AppRoutes.taskList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPageIndicator(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            page.image,
            height: 300,
          ),
          const SizedBox(height: 40),
          Text(page.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    final indicators = <Widget>[];
    for (var i = 0; i < _pages.length; i++) {
      indicators.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return indicators;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 8,
      width: isActive ? 24.0 : 16.0,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).primaryColor : Colors.grey,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    await _onboardingService.setOnboardingCompleted();
    _navigateToHome();
  }
}

class OnboardingPage {
  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
  final String title;
  final String description;
  final String image;
}
