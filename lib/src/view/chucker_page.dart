import 'dart:io';

import 'package:chucker_flutter/src/helpers/shared_preferences_manager.dart';
import 'package:chucker_flutter/src/models/api_response.dart';
import 'package:chucker_flutter/src/view/api_detail_page.dart';
import 'package:chucker_flutter/src/view/helper/chucker_ui_helper.dart';
import 'package:chucker_flutter/src/view/helper/colors.dart';
import 'package:chucker_flutter/src/view/helper/http_methods.dart';
import 'package:chucker_flutter/src/view/settings_page.dart';
import 'package:chucker_flutter/src/view/tabs/apis_listing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Modern Chucker Main Page
class ChuckerPage extends StatefulWidget {
  const ChuckerPage({Key? key}) : super(key: key);

  @override
  State<ChuckerPage> createState() => _ChuckerPageState();
}

class _ChuckerPageState extends State<ChuckerPage> with TickerProviderStateMixin {
  var _httpMethod = ChuckerUiHelper.settings.httpMethod;
  List<ApiResponse> _apis = List.empty();
  var _query = '';
  late TabController _tabController;

  final _tabsHeadings = [
    _TabModel(
      label: 'All Requests',
      icon: Icons.all_inclusive_rounded,
      index: 0,
    ),
    _TabModel(
      label: 'Success',
      icon: Icons.check_circle_rounded,
      index: 1,
    ),
    _TabModel(
      label: 'Failed',
      icon: Icons.error_rounded,
      index: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final sharedPreferencesManager = SharedPreferencesManager.getInstance();
    _apis = await sharedPreferencesManager.getAllApiResponses();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildModernAppBar(context),
      body: DraggableScrollableSheet(
        shouldCloseOnMinExtent: false,
        initialChildSize: 0.925,
        minChildSize: 0.925,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              _buildModernFilterSection(),
              _ScrollAwareHeader(
                scrollController: scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildModernTabBar(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  key: const Key('apis_tab_bar_view'),
                  children: [
                    ApisListingTabView(
                      scrollController: scrollController,
                      key: const Key('all_tab_view'),
                      apis: _allApis(),
                      onRefresh: _init,
                      onDelete: _deleteAnApi,
                      onChecked: _selectAnApi,
                      showDelete: _selectedApis.isEmpty,
                      onItemPressed: _openDetails,
                    ),
                    ApisListingTabView(
                      scrollController: scrollController,
                      apis: _successApis(),
                      onRefresh: _init,
                      onDelete: _deleteAnApi,
                      onChecked: _selectAnApi,
                      showDelete: _selectedApis.isEmpty,
                      onItemPressed: _openDetails,
                    ),
                    ApisListingTabView(
                      scrollController: scrollController,                      
                      key: const Key('fail_tab_view'),
                      apis: _failedApis(),
                      onRefresh: _init,
                      onDelete: _deleteAnApi,
                      onChecked: _selectAnApi,
                      showDelete: _selectedApis.isEmpty,
                      onItemPressed: _openDetails,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final hasSelection = _selectedApis.isNotEmpty;

    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => ChuckerFlutter.navigatorObserver.navigator?.pop(),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: hasSelection
            ? Text(
                '${_selectedApis.length} selected',
                key: const ValueKey('selection'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chucker',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Network Inspector',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
                key: ValueKey('title'),
              ),
      ),
      actions: [
        if (hasSelection) ...[
          _ModernActionButton(
            icon: Icons.delete_rounded,
            onPressed: _deleteAllSelected,
            tooltip: 'Delete Selected',
          ),
          _ModernActionButton(
            icon: Icons.file_download_rounded,
            onPressed: exportAllSelected,
            tooltip: 'Export',
          ),
          _ModernActionButton(
            icon: Icons.close_rounded,
            onPressed: () => _selectDeselectAll(false),
            tooltip: 'Clear Selection',
          ),
        ] else ...[
          Theme(
            data: ThemeData(
              checkboxTheme: const CheckboxThemeData(
                side: BorderSide(color: Colors.white),
              ),
            ),
            child: Checkbox(
              tristate: true,
              value: _selectAllCheckState(),
              onChanged: (checked) => _selectDeselectAll(checked ?? false),
            ),
          ),
          _ModernActionButton(
            icon: Icons.settings_rounded,
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsSection() {
    final total = _apis.length;
    final success = _successApis(filterApply: false).length;
    final failed = _failedApis(filterApply: false).length;
    final avgResponseTime = _calculateAvgResponseTime();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.all_inclusive_rounded,
              label: 'Total',
              value: total.toString(),
              color: primaryColor,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_rounded,
              label: 'Success',
              value: success.toString(),
              color: Colors.green,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.error_rounded,
              label: 'Failed',
              value: failed.toString(),
              color: Colors.red,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.speed_rounded,
              label: 'Avg Time',
              value: '${avgResponseTime}ms',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arama çubuğu
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search URL, status code or path...',
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[600]),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // HTTP Method Filters
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Method:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: HttpMethod.values.map((method) {
                      final isSelected = _httpMethod == method;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _MethodFilterChip(
                          label: method.name.toUpperCase(),
                          isSelected: isSelected,
                          color: _getMethodColor(method),
                          onTap: () => setState(() => _httpMethod = method),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: _tabsHeadings.map((tab) {
          final count = tab.index == 0
              ? _allApis().length
              : tab.index == 1
                  ? _successApis(filterApply: false).length
                  : _failedApis(filterApply: false).length;

          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 16),
                const SizedBox(width: 6),
                Text('${tab.label} ($count)'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return Colors.blue;
      case HttpMethod.post:
        return Colors.green;
      case HttpMethod.put:
        return Colors.orange;
      case HttpMethod.delete:
        return Colors.red;
      case HttpMethod.patch:
        return Colors.purple;
      case HttpMethod.none:
        return Colors.grey;
    }
  }

  int _calculateAvgResponseTime() {
    if (_apis.isEmpty) return 0;
    final total = _apis.fold<int>(
      0,
      (sum, api) => sum + api.responseTime.difference(api.requestTime).inMilliseconds,
    );
    return total ~/ _apis.length;
  }

  List<ApiResponse> _allApis() {
    final query = _query.toLowerCase();
    var filtered = _apis.toList();

    if (_httpMethod != HttpMethod.none) {
      filtered = filtered.where((e) => e.method.toLowerCase() == _httpMethod.name).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((element) {
        return element.baseUrl.toLowerCase().contains(query) ||
            element.statusCode.toString().contains(query) ||
            element.path.toLowerCase().contains(query) ||
            element.requestTime.toString().contains(query);
      }).toList();
    }

    return filtered;
  }

  List<ApiResponse> _successApis({bool filterApply = true}) {
    final query = _query.toLowerCase();
    return _apis.where((element) {
      var success = element.statusCode > 199 && element.statusCode < 300;
      final methodFilter = element.method.toLowerCase() == _httpMethod.name;

      if (filterApply) {
        success = success && (_httpMethod == HttpMethod.none || methodFilter);
        if (query.isEmpty) return success;

        return success &&
            (element.baseUrl.toLowerCase().contains(query) ||
                element.statusCode.toString().contains(query) ||
                element.path.toLowerCase().contains(query) ||
                element.requestTime.toString().contains(query));
      }
      return success;
    }).toList();
  }

  List<ApiResponse> _failedApis({bool filterApply = true}) {
    final query = _query.toLowerCase();
    return _apis.where((element) {
      var failed = element.statusCode < 200 || element.statusCode > 299;
      final methodFilter = element.method.toLowerCase() == _httpMethod.name;

      if (filterApply) {
        failed = failed && (_httpMethod == HttpMethod.none || methodFilter);
        if (query.isEmpty) return failed;

        return failed &&
            (element.baseUrl.toLowerCase().contains(query) ||
                element.statusCode.toString().contains(query) ||
                element.path.toLowerCase().contains(query) ||
                element.requestTime.toString().contains(query));
      }
      return failed;
    }).toList();
  }

  List<ApiResponse> get _selectedApis => _apis.where((e) => e.checked).toList();

  Future<void> _deleteAnApi(String dateTime) async {
    var deleteConfirm = true;
    if (ChuckerUiHelper.settings.showDeleteConfirmDialog) {
      deleteConfirm = await _showModernDeleteDialog(
            title: 'Delete Request',
            message: 'Are you sure you want to delete this request?',
          ) ??
          false;
    }
    if (deleteConfirm) {
      final sharedPreferencesManager = SharedPreferencesManager.getInstance();
      await sharedPreferencesManager.deleteAnApi(dateTime);
      setState(() => _apis.removeWhere((e) => e.requestTime.toString() == dateTime));
    }
  }

  Future<void> _deleteAllSelected() async {
    var deleteConfirm = true;
    if (ChuckerUiHelper.settings.showDeleteConfirmDialog) {
      deleteConfirm = await _showModernDeleteDialog(
            title: 'Delete Selected',
            message: '${_selectedApis.length} requests will be deleted. Do you want to continue?',
          ) ??
          false;
    }
    if (deleteConfirm) {
      final dateTimes = _selectedApis.map((e) => e.requestTime.toString()).toList();
      final sharedPreferencesManager = SharedPreferencesManager.getInstance();
      await sharedPreferencesManager.deleteSelected(dateTimes);
      setState(() => _apis.removeWhere((e) => dateTimes.contains(e.requestTime.toString())));
    }
  }

  Future<bool?> _showModernDeleteDialog({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> exportAllSelected() async {
    try {
      final fileName = await _showFileNameDialog() ?? 'exported_apis';
      if (fileName == 'cancel' || fileName.isEmpty) return;

      final rows = <List<dynamic>>[
        ['Method', 'Status Code', 'Base URL', 'Path', 'Response Time (s)']
      ];

      for (var api in _selectedApis) {
        final responseTime = api.responseTime.difference(api.requestTime).inMilliseconds / 1000;
        rows.add([api.method, api.statusCode, api.baseUrl, api.path, responseTime]);
      }

      final csvData = _convertToCsv(rows);
      final directory = await getApplicationDocumentsDirectory();
      final date = DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');
      final filePath = '${directory.path}/$fileName-$date.csv';

      await File(filePath).writeAsString(csvData);
      await _showResultDialog(isSuccess: true, message: 'File saved at:\n$filePath');
    } catch (e) {
      await _showResultDialog(isSuccess: false, message: 'Error: $e');
    }
  }

  String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((value) {
        if (value is String && value.contains(',')) {
          return '"$value"';
        }
        return value.toString();
      }).join(',');
    }).join('\n');
  }

  Future<String?> _showFileNameDialog() {
    final controller = TextEditingController(text: 'exported_apis');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('File Name', style: TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'exported_apis',
            prefixIcon: const Icon(Icons.file_present_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResultDialog({required bool isSuccess, required String message}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Text(isSuccess ? 'Success' : 'Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectAnApi(String dateTime) {
    setState(() {
      _apis = _apis
          .map((e) => e.requestTime.toString() == dateTime ? e.copyWith(checked: !e.checked) : e)
          .toList();
    });
  }

  void _selectDeselectAll(bool select) {
    setState(() => _apis = _apis.map((e) => e.copyWith(checked: select)).toList());
  }

  bool? _selectAllCheckState() {
    if (_selectedApis.length == _apis.length) return true;
    if (_selectedApis.isNotEmpty) return null;
    return false;
  }

  void _openSettings() {
    ChuckerFlutter.navigatorObserver.navigator?.push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: ThemeData.light(useMaterial3: false),
          child: const SettingsPage(),
        ),
      ),
    );
  }

  void _openDetails(ApiResponse api) {
    ChuckerFlutter.navigatorObserver.navigator?.push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: ThemeData.light(useMaterial3: false),
          child: ApiDetailsPage(api: api),
        ),
      ),
    );
  }
}

// Modern Action Button Widget
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

// Stat Item Widget
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Stat Divider
class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// Method Filter Chip
class _MethodFilterChip extends StatelessWidget {
  const _MethodFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? color : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tab Model
class _TabModel {
  _TabModel({
    required this.label,
    required this.icon,
    required this.index,
  });

  final String label;
  final IconData icon;
  final int index;
}

class _ScrollAwareHeader extends StatefulWidget {
  const _ScrollAwareHeader({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  State<_ScrollAwareHeader> createState() => _ScrollAwareHeaderState();
}

class _ScrollAwareHeaderState extends State<_ScrollAwareHeader> {
  bool _isScrolled = false;
  static const double _scrollThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final bool shouldHide = widget.scrollController.hasClients && widget.scrollController.offset > _scrollThreshold;
    if (shouldHide != _isScrolled) {
      setState(() {
        _isScrolled = shouldHide;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      curve: Curves.easeInOut,
      child: _isScrolled ? const SizedBox(width: double.infinity) : widget.child,
    );
  }
}