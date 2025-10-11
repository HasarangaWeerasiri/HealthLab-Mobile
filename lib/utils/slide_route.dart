import 'package:flutter/material.dart';

class SlideRoute extends PageRouteBuilder {
  final Widget page;
  final SlideDirection direction;

  SlideRoute({
    required this.page,
    this.direction = SlideDirection.leftToRight,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return _ContentOnlySlideTransition(
              animation: animation,
              direction: direction,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class _ContentOnlySlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final SlideDirection direction;
  final Widget child;

  const _ContentOnlySlideTransition({
    required this.animation,
    required this.direction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const curve = Curves.easeInOut;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, _) {
        if (child is Scaffold) {
          final scaffold = child as Scaffold;
          
          return Scaffold(
            backgroundColor: scaffold.backgroundColor,
            body: _buildContentWithFixedHeader(context, scaffold.body, curvedAnimation),
            bottomNavigationBar: scaffold.bottomNavigationBar,
            floatingActionButton: scaffold.floatingActionButton,
            floatingActionButtonLocation: scaffold.floatingActionButtonLocation,
            drawer: scaffold.drawer,
            endDrawer: scaffold.endDrawer,
            bottomSheet: scaffold.bottomSheet,
            persistentFooterButtons: scaffold.persistentFooterButtons,
            resizeToAvoidBottomInset: scaffold.resizeToAvoidBottomInset,
            primary: scaffold.primary,
            drawerDragStartBehavior: scaffold.drawerDragStartBehavior,
            extendBody: scaffold.extendBody,
            extendBodyBehindAppBar: scaffold.extendBodyBehindAppBar,
            drawerScrimColor: scaffold.drawerScrimColor,
            drawerEdgeDragWidth: scaffold.drawerEdgeDragWidth,
            drawerEnableOpenDragGesture: scaffold.drawerEnableOpenDragGesture,
            endDrawerEnableOpenDragGesture: scaffold.endDrawerEnableOpenDragGesture,
          );
        }
        
        // Fallback to regular slide transition
        return Transform.translate(
          offset: _getSlideOffset(context, curvedAnimation),
          child: child,
        );
      },
    );
  }

  Widget _buildContentWithFixedHeader(BuildContext context, Widget? body, Animation<double> animation) {
    if (body == null) return const SizedBox.shrink();

    // If body is a Column, we'll try to keep the first child (header) fixed
    if (body is Column && body.children.length >= 2) {
      final header = body.children.first;
      final contentChildren = body.children.skip(1).toList();
      
      return Column(
        children: [
          // Fixed header
          header,
          // Sliding content area
          Expanded(
            child: Transform.translate(
              offset: _getSlideOffset(context, animation),
              child: Column(
                children: contentChildren,
              ),
            ),
          ),
        ],
      );
    }

    // For other body types, slide the entire body
    return Transform.translate(
      offset: _getSlideOffset(context, animation),
      child: body,
    );
  }

  Offset _getSlideOffset(BuildContext context, Animation<double> animation) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (direction) {
      case SlideDirection.leftToRight:
        return Offset(
          (animation.value - 1) * screenWidth,
          0,
        );
      case SlideDirection.rightToLeft:
        return Offset(
          (1 - animation.value) * screenWidth,
          0,
        );
      case SlideDirection.topToBottom:
        return Offset(
          0,
          (animation.value - 1) * MediaQuery.of(context).size.height,
        );
      case SlideDirection.bottomToTop:
        return Offset(
          0,
          (1 - animation.value) * MediaQuery.of(context).size.height,
        );
    }
  }
}

enum SlideDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}
