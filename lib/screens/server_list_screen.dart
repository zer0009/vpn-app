import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/server_list_item.dart';
import '../models/vpn_server.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<VpnServer> filteredServers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final provider = Provider.of<VpnProvider>(context, listen: false);
    setState(() {
      filteredServers = provider.servers.where((server) {
        final searchTerm = _searchController.text.toLowerCase();
        return server.country.toLowerCase().contains(searchTerm) ||
               server.city.toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecommendedServers(),
                  _buildAllServers(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              _buildBackButton(),
              const SizedBox(width: 16),
              const Text(
                'Select Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search locations...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Recommended'),
          Tab(text: 'All Locations'),
        ],
      ),
    );
  }

  Widget _buildRecommendedServers() {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        final recommendedServers = provider.servers.take(3).toList();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recommendedServers.length + 1,  // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSectionHeader('Recommended for you');
            }
            return ServerListItem(
              server: recommendedServers[index - 1],
              isRecommended: true,
              onTap: () => _selectServer(provider, recommendedServers[index - 1]),
            );
          },
        );
      },
    );
  }

  Widget _buildAllServers() {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        final servers = _searchController.text.isEmpty 
            ? provider.servers 
            : filteredServers;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: servers.length,
          itemBuilder: (context, index) => ServerListItem(
            server: servers[index],
            onTap: () => _selectServer(provider, servers[index]),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _selectServer(VpnProvider provider, VpnServer server) async {
    await provider.setSelectedServer(server);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}