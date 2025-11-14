import 'package:chucker_flutter/src/helpers/extensions.dart';
import 'package:chucker_flutter/src/localization/localization.dart';
import 'package:chucker_flutter/src/models/api_response.dart';
import 'package:chucker_flutter/src/view/helper/colors.dart';
import 'package:flutter/material.dart';

/// Modern API List Item Widget
class ApisListingItemWidget extends StatelessWidget {
  const ApisListingItemWidget({
    required this.baseUrl,
    required this.dateTime,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.onDelete,
    required this.checked,
    required this.onChecked,
    required this.showDelete,
    required this.onPressed,
    required this.request,
    Key? key,
  }) : super(key: key);

  final String baseUrl;
  final String path;
  final String method;
  final int statusCode;
  final DateTime dateTime;
  final void Function(String) onDelete;
  final bool checked;
  final void Function(String) onChecked;
  final bool showDelete;
  final VoidCallback onPressed;
  final dynamic request;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checked ? primaryColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Method, Status, Checkbox
                Row(
                  children: [
                    _ModernMethodChip(method: method),
                    const SizedBox(width: 8),
                    _ModernStatusBadge(statusCode: statusCode),
                    const Spacer(),
                    if (showDelete)
                      _ModernDeleteButton(
                        onPressed: () => onDelete(dateTime.toString()),
                      ),
                    const SizedBox(width: 8),
                    _ModernCheckbox(
                      checked: checked,
                      onChanged: () => onChecked(dateTime.toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Path
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        path,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Base URL
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        baseUrl.isEmpty ? 'N/A' : baseUrl,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                if (request.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Request Preview
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            request.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(dateTime),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _ModernMethodChip extends StatelessWidget {
  const _ModernMethodChip({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = _getMethodColor(method);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMethodIcon(method),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            method.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'get':
        return Colors.blue;
      case 'post':
        return Colors.green;
      case 'put':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      case 'patch':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'get':
        return Icons.download_rounded;
      case 'post':
        return Icons.upload_rounded;
      case 'put':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_outline_rounded;
      case 'patch':
        return Icons.build_rounded;
      default:
        return Icons.http_rounded;
    }
  }
}

class _ModernStatusBadge extends StatelessWidget {
  const _ModernStatusBadge({required this.statusCode});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final isError = statusCode >= 400;
    
    final color = isSuccess
        ? Colors.green
        : isError
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_rounded
                : isError
                    ? Icons.error_rounded
                    : Icons.info_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            statusCode.toString(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDeleteButton extends StatelessWidget {
  const _ModernDeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.delete_rounded,
            size: 18,
            color: Colors.red[700],
          ),
        ),
      ),
    );
  }
}

class _ModernCheckbox extends StatelessWidget {
  const _ModernCheckbox({
    required this.checked,
    required this.onChanged,
  });

  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? primaryColor.withOpacity(0.1) : Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: checked ? primaryColor : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: checked
              ? const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: primaryColor,
                )
              : null,
        ),
      ),
    );
  }
}