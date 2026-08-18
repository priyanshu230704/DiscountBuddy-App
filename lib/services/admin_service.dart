import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/admin/app_banner.dart';
import '../models/admin/spin_campaign.dart';
import '../models/admin/spin_item.dart';
import '../models/admin/spin_history.dart';

class PaginatedResult<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResult({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final ApiService _apiService = ApiService();

  List<T> _extractList<T>(Map<String, dynamic> response, T Function(Map<String, dynamic>) fromJson) {
    List rawList = [];
    if (response['results'] != null && response['results'] is List) {
      rawList = response['results'] as List;
    } else if (response['data'] != null && response['data'] is List) {
      rawList = response['data'] as List;
    }
    return rawList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  PaginatedResult<T> _extractPaginated<T>(Map<String, dynamic> response, T Function(Map<String, dynamic>) fromJson) {
    final list = _extractList(response, fromJson);
    final count = response['count'] as int? ?? list.length;
    final next = response['next'] as String?;
    final previous = response['previous'] as String?;
    return PaginatedResult(
      count: count,
      next: next,
      previous: previous,
      results: list,
    );
  }

  // ==================== BANNERS ====================

  Future<PaginatedResult<AppBanner>> getBanners({int page = 1, bool? isVisible}) async {
    try {
      final queryParams = <String, String>{'page': page.toString()};
      if (isVisible != null) {
        queryParams['is_visible'] = isVisible.toString();
      }
      final response = await _apiService.get(
        '/admin/banners',
        queryParameters: queryParams,
        type: ApiType.admin,
      );
      return _extractPaginated(response, AppBanner.fromJson);
    } catch (e) {
      debugPrint('AdminService.getBanners error: $e');
      rethrow;
    }
  }

  Future<AppBanner> getBanner(int id) async {
    final response = await _apiService.get(
      '/admin/banners/$id',
      type: ApiType.admin,
    );
    return AppBanner.fromJson(response);
  }

  Future<AppBanner> createBanner({
    String? title,
    String? body,
    String ctaUrl = '',
    int priority = 0,
    bool isVisible = true,
    File? imageFile,
  }) async {
    final fields = <String, String>{
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      'cta_url': ctaUrl,
      'priority': priority.toString(),
      'is_visible': isVisible.toString(),
    };

    Map<String, dynamic> response;
    if (imageFile != null) {
      final files = <String, http.MultipartFile>{
        'image': await http.MultipartFile.fromPath('image', imageFile.path),
      };
      response = await _apiService.postMultipart(
        '/admin/banners',
        fields: fields,
        files: files,
        type: ApiType.admin,
      );
    } else {
      final jsonBody = <String, dynamic>{
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        'cta_url': ctaUrl,
        'priority': priority,
        'is_visible': isVisible,
      };
      response = await _apiService.post(
        '/admin/banners',
        body: jsonBody,
        type: ApiType.admin,
      );
    }
    return AppBanner.fromJson(response);
  }

  Future<AppBanner> updateBanner(
    int id, {
    String? title,
    String? body,
    String? ctaUrl,
    int? priority,
    bool? isVisible,
    File? imageFile,
  }) async {
    if (imageFile != null) {
      final fields = <String, String>{};
      if (title != null) fields['title'] = title;
      if (body != null) fields['body'] = body;
      if (ctaUrl != null) fields['cta_url'] = ctaUrl;
      if (priority != null) fields['priority'] = priority.toString();
      if (isVisible != null) fields['is_visible'] = isVisible.toString();

      final files = <String, http.MultipartFile>{
        'image': await http.MultipartFile.fromPath('image', imageFile.path),
      };
      final response = await _apiService.patchMultipart(
        '/admin/banners/$id',
        fields: fields,
        files: files,
        type: ApiType.admin,
      );
      return AppBanner.fromJson(response);
    } else {
      final jsonBody = <String, dynamic>{};
      if (title != null) jsonBody['title'] = title;
      if (body != null) jsonBody['body'] = body;
      if (ctaUrl != null) jsonBody['cta_url'] = ctaUrl;
      if (priority != null) jsonBody['priority'] = priority;
      if (isVisible != null) jsonBody['is_visible'] = isVisible;

      final response = await _apiService.patch(
        '/admin/banners/$id',
        body: jsonBody,
        type: ApiType.admin,
      );
      return AppBanner.fromJson(response);
    }
  }

  Future<void> deleteBanner(int id) async {
    await _apiService.delete('/admin/banners/$id', type: ApiType.admin);
  }

  Future<bool> toggleBannerVisible(int id) async {
    final response = await _apiService.post(
      '/admin/banners/$id/toggle-visible',
      type: ApiType.admin,
    );
    return response['is_visible'] as bool? ?? false;
  }

  Future<bool> toggleBannerActive(int id) => toggleBannerVisible(id);

  // ==================== SPIN TO WIN CAMPAIGNS ====================

  Future<PaginatedResult<SpinCampaign>> getCampaigns({int page = 1}) async {
    try {
      final response = await _apiService.get(
        '/admin/spin-to-win/campaigns',
        queryParameters: {'page': page.toString()},
        type: ApiType.admin,
      );
      return _extractPaginated(response, SpinCampaign.fromJson);
    } catch (e) {
      debugPrint('AdminService.getCampaigns error: $e');
      rethrow;
    }
  }

  Future<SpinCampaign> getCampaign(int id) async {
    final response = await _apiService.get(
      '/admin/spin-to-win/campaigns/$id',
      type: ApiType.admin,
    );
    return SpinCampaign.fromJson(response);
  }

  Future<SpinCampaign> createCampaign({
    required String title,
    String description = '',
    bool isActive = true,
    int maxSpinsPerUserPerDay = 1,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'is_active': isActive,
      'max_spins_per_user_per_day': maxSpinsPerUserPerDay,
    };
    final response = await _apiService.post(
      '/admin/spin-to-win/campaigns',
      body: body,
      type: ApiType.admin,
    );
    return SpinCampaign.fromJson(response);
  }

  Future<SpinCampaign> updateCampaign(
    int id, {
    String? title,
    String? description,
    bool? isActive,
    int? maxSpinsPerUserPerDay,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive;
    if (maxSpinsPerUserPerDay != null) body['max_spins_per_user_per_day'] = maxSpinsPerUserPerDay;

    final response = await _apiService.patch(
      '/admin/spin-to-win/campaigns/$id',
      body: body,
      type: ApiType.admin,
    );
    return SpinCampaign.fromJson(response);
  }

  Future<void> deleteCampaign(int id) async {
    await _apiService.delete('/admin/spin-to-win/campaigns/$id', type: ApiType.admin);
  }

  // ==================== SPIN TO WIN ITEMS ====================

  Future<PaginatedResult<SpinItem>> getItems({int? campaignId, int page = 1}) async {
    try {
      final queryParams = <String, String>{'page': page.toString()};
      if (campaignId != null) queryParams['campaign'] = campaignId.toString();

      final response = await _apiService.get(
        '/admin/spin-to-win/items',
        queryParameters: queryParams,
        type: ApiType.admin,
      );
      return _extractPaginated(response, SpinItem.fromJson);
    } catch (e) {
      debugPrint('AdminService.getItems error: $e');
      rethrow;
    }
  }

  Future<SpinItem> getItem(int id) async {
    final response = await _apiService.get(
      '/admin/spin-to-win/items/$id',
      type: ApiType.admin,
    );
    return SpinItem.fromJson(response);
  }

  Future<SpinItem> createItem({
    required int campaignId,
    required String title,
    String description = '',
    String icon = '🎁',
    File? imageFile,
    required SpinItemType itemType,
    String promoCodeValue = '',
    double? discountPercentage,
    int minSpinsBeforeWin = 0,
    int? stockLimit,
    int probabilityWeight = 10,
    int sliceIndex = 0,
    bool isActive = true,
  }) async {
    if (imageFile != null) {
      final fields = <String, String>{
        'campaign': campaignId.toString(),
        'title': title,
        'description': description,
        'icon': icon,
        'item_type': itemType.toValue(),
        'promo_code_value': promoCodeValue,
        'min_spins_before_win': minSpinsBeforeWin.toString(),
        'probability_weight': probabilityWeight.toString(),
        'slice_index': sliceIndex.toString(),
        'is_active': isActive.toString(),
      };
      if (discountPercentage != null) fields['discount_percentage'] = discountPercentage.toString();
      if (stockLimit != null) fields['stock_limit'] = stockLimit.toString();

      final files = <String, http.MultipartFile>{
        'image': await http.MultipartFile.fromPath('image', imageFile.path),
      };
      final response = await _apiService.postMultipart(
        '/admin/spin-to-win/items',
        fields: fields,
        files: files,
        type: ApiType.admin,
      );
      return SpinItem.fromJson(response);
    } else {
      final body = <String, dynamic>{
        'campaign': campaignId,
        'title': title,
        'description': description,
        'icon': icon,
        'item_type': itemType.toValue(),
        'promo_code_value': promoCodeValue,
        'discount_percentage': discountPercentage,
        'min_spins_before_win': minSpinsBeforeWin,
        'stock_limit': stockLimit,
        'probability_weight': probabilityWeight,
        'slice_index': sliceIndex,
        'is_active': isActive,
      };
      final response = await _apiService.post(
        '/admin/spin-to-win/items',
        body: body,
        type: ApiType.admin,
      );
      return SpinItem.fromJson(response);
    }
  }

  Future<SpinItem> updateItem(
    int id, {
    int? campaignId,
    String? title,
    String? description,
    String? icon,
    File? imageFile,
    SpinItemType? itemType,
    String? promoCodeValue,
    double? discountPercentage,
    int? minSpinsBeforeWin,
    int? stockLimit,
    int? probabilityWeight,
    int? sliceIndex,
    bool? isActive,
  }) async {
    if (imageFile != null) {
      final fields = <String, String>{};
      if (campaignId != null) fields['campaign'] = campaignId.toString();
      if (title != null) fields['title'] = title;
      if (description != null) fields['description'] = description;
      if (icon != null) fields['icon'] = icon;
      if (itemType != null) fields['item_type'] = itemType.toValue();
      if (promoCodeValue != null) fields['promo_code_value'] = promoCodeValue;
      if (discountPercentage != null) fields['discount_percentage'] = discountPercentage.toString();
      if (minSpinsBeforeWin != null) fields['min_spins_before_win'] = minSpinsBeforeWin.toString();
      if (stockLimit != null) fields['stock_limit'] = stockLimit.toString();
      if (probabilityWeight != null) fields['probability_weight'] = probabilityWeight.toString();
      if (sliceIndex != null) fields['slice_index'] = sliceIndex.toString();
      if (isActive != null) fields['is_active'] = isActive.toString();

      final files = <String, http.MultipartFile>{
        'image': await http.MultipartFile.fromPath('image', imageFile.path),
      };
      final response = await _apiService.patchMultipart(
        '/admin/spin-to-win/items/$id',
        fields: fields,
        files: files,
        type: ApiType.admin,
      );
      return SpinItem.fromJson(response);
    } else {
      final body = <String, dynamic>{};
      if (campaignId != null) body['campaign'] = campaignId;
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (icon != null) body['icon'] = icon;
      if (itemType != null) body['item_type'] = itemType.toValue();
      if (promoCodeValue != null) body['promo_code_value'] = promoCodeValue;
      if (discountPercentage != null) body['discount_percentage'] = discountPercentage;
      if (minSpinsBeforeWin != null) body['min_spins_before_win'] = minSpinsBeforeWin;
      if (stockLimit != null) body['stock_limit'] = stockLimit;
      if (probabilityWeight != null) body['probability_weight'] = probabilityWeight;
      if (sliceIndex != null) body['slice_index'] = sliceIndex;
      if (isActive != null) body['is_active'] = isActive;

      final response = await _apiService.patch(
        '/admin/spin-to-win/items/$id',
        body: body,
        type: ApiType.admin,
      );
      return SpinItem.fromJson(response);
    }
  }

  Future<void> deleteItem(int id) async {
    await _apiService.delete('/admin/spin-to-win/items/$id', type: ApiType.admin);
  }

  // ==================== SPIN HISTORY ====================

  Future<PaginatedResult<UserSpinResult>> getSpinHistory({int page = 1}) async {
    try {
      final response = await _apiService.get(
        '/admin/spin-to-win/history',
        queryParameters: {'page': page.toString()},
        type: ApiType.admin,
      );
      return _extractPaginated(response, UserSpinResult.fromJson);
    } catch (e) {
      debugPrint('AdminService.getSpinHistory error: $e');
      rethrow;
    }
  }
}
