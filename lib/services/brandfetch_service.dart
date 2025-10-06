import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BrandfetchService {
	BrandfetchService._();

	static final BrandfetchService instance = BrandfetchService._();

	String get _apiKey => dotenv.env['BRANDFETCH_API_KEY'] ?? '';

	Future<BrandInfo?> fetchByDomain(String domainOrUrl) async {
		if (_apiKey.isEmpty) {
			throw BrandfetchException('Missing BRANDFETCH_API_KEY in .env');
		}
		final String domain = _normalizeDomain(domainOrUrl);
		if (domain.isEmpty) return null;
		final uri = Uri.parse('https://api.brandfetch.io/v2/brands/$domain');
		final res = await http.get(
			uri,
			headers: <String, String>{
				'Authorization': 'Bearer $_apiKey',
				'Accept': 'application/json',
			},
		);
		if (res.statusCode == 200) {
			final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
			return _mapBrandInfo(data);
		}
		throw BrandfetchException('Brandfetch error ${res.statusCode}: ${res.body}');
	}

	Future<List<BrandInfo>> searchBrands(String query) async {
		if (_apiKey.isEmpty) {
			throw BrandfetchException('Missing BRANDFETCH_API_KEY in .env');
		}
		final String q = query.trim();
		if (q.isEmpty) return <BrandInfo>[];
		final uri = Uri.parse('https://api.brandfetch.io/v2/search/${Uri.encodeComponent(q)}');
		final res = await http.get(
			uri,
			headers: <String, String>{
				'Authorization': 'Bearer $_apiKey',
				'Accept': 'application/json',
			},
		);
		if (res.statusCode == 200) {
			final List<dynamic> data = json.decode(res.body) as List<dynamic>;
			return data
				.map((dynamic e) => e is Map<String, dynamic> ? _mapSearchItem(e) : null)
				.whereType<BrandInfo>()
				.toList(growable: false);
		}
		throw BrandfetchException('Brandfetch error ${res.statusCode}: ${res.body}');
	}

	BrandInfo _mapSearchItem(Map<String, dynamic> data) {
		final String name = (data['name'] as String?) ?? '';
		final String website = (data['domain'] as String?) ?? (data['website'] as String?) ?? '';
		final String? icon = (data['icon'] as String?);
		final String? logo = icon?.isNotEmpty == true ? icon : _extractPreferredImageUrl(data['logos']);
		return BrandInfo(name: name.isNotEmpty ? name : website, websiteUrl: website, logoUrl: logo);
	}

	BrandInfo? _mapBrandInfo(Map<String, dynamic> data) {
		final String? name = data['name'] as String?;
		final String? domain = (data['domain'] as String?) ?? (data['website'] as String?);
		final String? icon = (data['icon'] as String?);
		final String? logo = icon?.isNotEmpty == true ? icon : _extractPreferredImageUrl(data['logos']);

		if (name == null && (domain == null || domain.isEmpty)) return null;
		return BrandInfo(
			name: name ?? domain ?? '',
			websiteUrl: domain ?? '',
			logoUrl: logo,
		);
	}

	String? _extractPreferredImageUrl(dynamic logosField) {
		// Expecting logosField to be a List of objects with `files` array.
		if (logosField is! List) return null;
		// Flatten all files
		final List<Map<String, dynamic>> files = <Map<String, dynamic>>[];
		for (final dynamic entry in logosField) {
			if (entry is Map<String, dynamic>) {
				final List<dynamic>? f = entry['files'] as List<dynamic>?;
				if (f != null) {
					for (final dynamic file in f) {
						if (file is Map<String, dynamic>) files.add(file);
					}
				}
			}
		}
		if (files.isEmpty) return null;
		// Prefer PNG (Flutter renders it natively). Some results default to SVG.
		for (final Map<String, dynamic> f in files) {
			final String? format = f['format'] as String?;
			final String? url = f['url'] as String?;
			if ((format?.toLowerCase() == 'png') && (url != null && url.isNotEmpty)) {
				return url;
			}
		}
		// Fallback to any available URL
		for (final Map<String, dynamic> f in files) {
			final String? url = f['url'] as String?;
			if (url != null && url.isNotEmpty) return url;
		}
		return null;
	}

	String _normalizeDomain(String input) {
		String v = input.trim();
		if (v.isEmpty) return '';
		v = v.replaceAll(RegExp(r'^https?://'), '');
		v = v.split('/').first;
		return v;
	}
}

class BrandInfo {
	final String name;
	final String websiteUrl;
	final String? logoUrl;
	const BrandInfo({required this.name, required this.websiteUrl, this.logoUrl});
}

class BrandfetchException implements Exception {
	final String message;
	BrandfetchException(this.message);
	@override
	String toString() => message;
}
