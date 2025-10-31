import 'package:chucker_flutter/src/helpers/extensions.dart';
import 'package:chucker_flutter/src/localization/localization.dart';
import 'package:chucker_flutter/src/models/api_response.dart';
import 'package:chucker_flutter/src/view/helper/colors.dart';
import 'package:chucker_flutter/src/view/json_tree/json_tree.dart';
import 'package:chucker_flutter/src/view/tabs/overview.dart';
import 'package:chucker_flutter/src/view/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Modern API Details Page with enhanced UI
class ApiDetailsPage extends StatefulWidget {
  const ApiDetailsPage({required this.api, Key? key}) : super(key: key);

  final ApiResponse api;

  @override
  State<ApiDetailsPage> createState() => _ApiDetailsPageState();
}

class _ApiDetailsPageState extends State<ApiDetailsPage>
    with TickerProviderStateMixin {
  var _jsonRequestPreviewType = _JsonPreviewType.tree;
  var _jsonResponsePreviewType = _JsonPreviewType.tree;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildModernAppBar(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildModernTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    OverviewTabView(api: widget.api),
                    _RequestTab(
                      jsonPreviewType: _jsonRequestPreviewType,
                      onShufflePreview: _shuffleRequestPreviewType,
                      json: widget.api.request,
                      prettyJson: widget.api.prettyJsonRequest,
                      apiResponse: widget.api,
                    ),
                    _ResponseTab(
                      jsonPreviewType: _jsonResponsePreviewType,
                      onShufflePreview: _shuffleResponsePreviewType,
                      json: widget.api.body,
                      prettyJson: widget.api.prettyJson,
                      apiResponse: widget.api,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => context.navigator.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        _ModernActionButton(
          icon: Icons.content_copy_rounded,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.api.toString()));
            _showSnackBar(context, 'Copied');
          },
          tooltip: 'Copy',
        ),
        _ModernActionButton(
          icon: Icons.share_rounded,
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                text: widget.api.toString(),
                sharePositionOrigin: Rect.fromLTWH(
                  0,
                  0,
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height / 2,
                ),
              ),
            );
          },
          tooltip: 'Share',
        ),
        _ModernActionButton(
          icon: Icons.terminal_rounded,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.api.toCurl()));
            _showSnackBar(context, 'cURL command copied');
          },
          tooltip: 'Copy cURL',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildModernTabBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            icon: const Icon(Icons.dashboard_rounded, size: 20),
            text: Localization.strings['overview'],
          ),
          Tab(
            icon: const Icon(Icons.upload_rounded, size: 20),
            text: Localization.strings['request'],
          ),
          Tab(
            icon: const Icon(Icons.download_rounded, size: 20),
            text: Localization.strings['response'],
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    final status = widget.api.statusCode;
    if (status >= 200 && status < 300) return 'Success · $status';
    if (status >= 400) return 'Error · $status';
    return 'Status · $status';
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shuffleResponsePreviewType() {
    setState(() {
      _jsonResponsePreviewType = _jsonResponsePreviewType == _JsonPreviewType.tree
          ? _JsonPreviewType.text
          : _JsonPreviewType.tree;
    });
  }

  void _shuffleRequestPreviewType() {
    setState(() {
      _jsonRequestPreviewType = _jsonRequestPreviewType == _JsonPreviewType.tree
          ? _JsonPreviewType.text
          : _JsonPreviewType.tree;
    });
  }
}

class _ModernActionButton extends StatelessWidget {
  const _ModernActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: UnconstrainedBox(
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(icon, size: 20),
            onPressed: onPressed,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
      ),
    );
  }
}

class _ModernPreviewControl extends StatelessWidget {
  const _ModernPreviewControl({
    required this.jsonPreviewType,
    required this.onPreviewPressed,
    required this.onCopyPressed,
  });

  final _JsonPreviewType jsonPreviewType;
  final VoidCallback onPreviewPressed;
  final VoidCallback onCopyPressed;

  @override
  Widget build(BuildContext context) {
    final isTreeMode = jsonPreviewType == _JsonPreviewType.tree;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.visibility_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const Spacer(),
              Material(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onCopyPressed,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.content_copy_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ViewModeChip(
                  label: 'Tree',
                  isSelected: isTreeMode,
                  onTap: isTreeMode ? null : onPreviewPressed,
                  icon: Icons.account_tree_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ViewModeChip(
                  label: 'Text',
                  isSelected: !isTreeMode,
                  onTap: !isTreeMode ? null : onPreviewPressed,
                  icon: Icons.text_fields_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  const _ViewModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponseTab extends StatelessWidget {
  const _ResponseTab({
    required this.apiResponse,
    required this.jsonPreviewType,
    required this.onShufflePreview,
    required this.json,
    required this.prettyJson,
  });

  final ApiResponse apiResponse;
  final dynamic json;
  final String prettyJson;
  final _JsonPreviewType jsonPreviewType;
  final VoidCallback onShufflePreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _ModernPreviewControl(
              jsonPreviewType: jsonPreviewType,
              onCopyPressed: _copyJsonResponse,
              onPreviewPressed: onShufflePreview,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildContentCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: _renderJsonWidget(context),
    );
  }

  void _copyJsonResponse() {
    Clipboard.setData(ClipboardData(text: prettyJson));
  }

  Widget _renderJsonWidget(BuildContext context) {
    switch (jsonPreviewType) {
      case _JsonPreviewType.tree:
        return JsonTree(json: json);
      case _JsonPreviewType.text:
        return SelectableText(
          prettyJson,
          style: context.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          textDirection: TextDirection.ltr,
        );
    }
  }
}

class _RequestTab extends StatelessWidget {
  const _RequestTab({
    required this.apiResponse,
    required this.jsonPreviewType,
    required this.onShufflePreview,
    required this.json,
    required this.prettyJson,
  });

  final ApiResponse apiResponse;
  final dynamic json;
  final String prettyJson;
  final _JsonPreviewType jsonPreviewType;
  final VoidCallback onShufflePreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _ModernPreviewControl(
              jsonPreviewType: jsonPreviewType,
              onCopyPressed: _copyJsonRequest,
              onPreviewPressed: onShufflePreview,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildContentCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: _renderJsonWidget(context),
    );
  }

  void _copyJsonRequest() {
    Clipboard.setData(ClipboardData(text: prettyJson));
  }

  Widget _renderJsonWidget(BuildContext context) {
    switch (jsonPreviewType) {
      case _JsonPreviewType.tree:
        return JsonTree(json: json);
      case _JsonPreviewType.text:
        return SelectableText(
          prettyJson,
          style: context.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          textDirection: TextDirection.ltr,
        );
    }
  }
}

enum _JsonPreviewType {
  tree,
  text,
}