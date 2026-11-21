import 'package:flutter/material.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: const [
          AppPageHeader(title: '课表'),
          SizedBox(height: 24),
          AppEmptyState(
            icon: Icons.grid_view_rounded,
            title: '周课表正在制作',
            message: '七天与全部节次将在这里完整展示，点开课程即可查看详情。',
          ),
        ],
      ),
    );
  }
}
