import 'package:flutter/cupertino.dart';

/// 精美的上下文菜单组件，基于地图菜单的设计
class ElegantContextMenu extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData headerIcon;
  final Color headerIconColor;
  final List<ElegantMenuOption> options;
  final VoidCallback? onCancel;

  const ElegantContextMenu({
    super.key,
    required this.title,
    this.subtitle,
    required this.headerIcon,
    this.headerIconColor = CupertinoColors.systemBlue,
    required this.options,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 头部信息
            _buildHeader(),
            
            // 菜单选项
            _buildMenuOptions(context),
            
            // 底部安全区域
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  headerIconColor,
                  headerIconColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: headerIconColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              headerIcon,
              color: CupertinoColors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // 副标题
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            _buildMenuOption(options[i]),
            if (i < options.length - 1) _buildMenuDivider(),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuOption(ElegantMenuOption option) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: option.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                option.icon,
                color: option.color,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 文本信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: option.isDestructive 
                          ? CupertinoColors.systemRed 
                          : CupertinoColors.label,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 箭头图标
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 68),
      height: 0.5,
      color: CupertinoColors.systemGrey4.withValues(alpha: 0.6),
    );
  }
}

/// 菜单选项数据类
class ElegantMenuOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final bool isDestructive;
  final VoidCallback onTap;

  const ElegantMenuOption({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = CupertinoColors.systemBlue,
    this.isDestructive = false,
    required this.onTap,
  });
}

/// 显示精美的上下文菜单
void showElegantContextMenu({
  required BuildContext context,
  required String title,
  String? subtitle,
  required IconData headerIcon,
  Color headerIconColor = CupertinoColors.systemBlue,
  required List<ElegantMenuOption> options,
}) {
  showCupertinoModalPopup(
    context: context,
    builder: (context) => ElegantContextMenu(
      title: title,
      subtitle: subtitle,
      headerIcon: headerIcon,
      headerIconColor: headerIconColor,
      options: options,
    ),
  );
}
