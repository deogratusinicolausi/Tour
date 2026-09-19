import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../utils/colors.dart';
import 'checkout_screen.dart';

class TripCartScreen extends StatefulWidget {
  const TripCartScreen({super.key});

  @override
  State<TripCartScreen> createState() => _TripCartScreenState();
}

class _TripCartScreenState extends State<TripCartScreen> {
  final _cartService = CartService();
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // --- TOP HEADER WITH LOTTIE ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.01,
                  ),
                  child: Row(
                    children: [
                      // Lottie Animation
                      SizedBox(
                        width: width * 0.15,
                        height: width * 0.15,
                        child: Lottie.asset(
                          'assets/animations/cart_animation.json',
                          repeat: true,
                          animate: true,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      // Title
                      Text(
                        'Trip Cart',
                        style: TextStyle(
                          fontSize: width * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Clear Cart Button (Only if cart has items)
                      if (_user != null)
                        StreamBuilder<TripCartModel?>(
                          stream: _cartService.getCart(_user!.uid),
                          builder: (context, snapshot) {
                            final cart = snapshot.data;
                            if (cart == null || cart.items.isEmpty) {
                              return const SizedBox();
                            }
                            return IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.white),
                              tooltip: 'Clear Cart',
                              onPressed: () => _confirmClear(width),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                // --- REST OF YOUR CONTENT ---
                Expanded(
                  child: _user == null
                      ? _buildLoginPrompt(width, height)
                      : StreamBuilder<TripCartModel?>(
                    stream: _cartService.getCart(_user!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      final cart = snapshot.data;
                      if (cart == null || cart.items.isEmpty) {
                        return _buildEmptyCart(width, height);
                      }
                      return Column(
                        children: [
                          // Items List
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.all(width * 0.04),
                              itemCount: cart.items.length,
                              itemBuilder: (context, i) => _buildCartItem(
                                cart.items[i],
                                width,
                                height,
                              ),
                            ),
                          ),
                          // Summary
                          _buildSummary(cart, width, height),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline,
              size: width * 0.2, color: Colors.white70),
          SizedBox(height: height * 0.02),
          Text(
            'Please Login',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            'Login to see your cart',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // Glass
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(Icons.shopping_cart_outlined,
                size: width * 0.15, color: Colors.white), // White icon
          ),
          SizedBox(height: height * 0.03),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text
            ),
          ),
          SizedBox(height: height * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.15),
            child: Text(
              'Add hotels, tours, beaches and more to your trip',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70, // White70 text
                fontSize: width * 0.035,
              ),
            ),
          ),
          SizedBox(height: height * 0.03),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.08,
                vertical: height * 0.015,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, double width, double height) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // GLASS
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)), // White border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(width * 0.035),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.itemImage.isNotEmpty
                      ? Image.network(
                    item.itemImage,
                    width: width * 0.2,
                    height: width * 0.2,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: width * 0.2,
                      height: width * 0.2,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image),
                    ),
                  )
                      : Container(
                    width: width * 0.2,
                    height: width * 0.2,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
                SizedBox(width: width * 0.03),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), // Glass badge
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.itemType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, // White text
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        item.itemName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.038,
                          color: Colors.white, // WHITE
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        '${item.currency} ${item.price.toStringAsFixed(0)} per person',
                        style: TextStyle(
                          color: AppColors.accentGold, // Gold for price
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.032,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeItem(item),
                ),
              ],
            ),
          ),

          // Quantity + Guests
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.012),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // Glass background
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                // Quantity
                Row(
                  children: [
                    _qtyBtn(
                      Icons.remove,
                          () => _updateQuantity(item, item.quantity - 1),
                      item.quantity > 1,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                          color: Colors.white, // White
                        ),
                      ),
                    ),
                    _qtyBtn(
                      Icons.add,
                          () => _updateQuantity(item, item.quantity + 1),
                      true,
                    ),
                  ],
                ),
                const Spacer(),
                // Total
                Text(
                  '${item.currency} ${item.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.accentGold, // Gold
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.045,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, bool enabled) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: width * 0.04),
      ),
    );
  }

  Widget _buildSummary(
      TripCartModel cart, double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Darker glass for the bottom
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items',
                style: TextStyle(
                  color: Colors.white70, // White70
                  fontSize: width * 0.035,
                ),
              ),
              Text(
                '${cart.itemCount}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.038,
                  color: Colors.white, // White
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.045,
                  color: Colors.white, // White
                ),
              ),
              Text(
                '${cart.currency} ${cart.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.055,
                  color: AppColors.accentGold, // Gold
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(cart: cart),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold, // Gold button
                foregroundColor: Colors.black, // Black text on gold
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'PROCEED TO CHECKOUT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeItem(CartItem item) async {
    if (_user == null) return;
    await _cartService.removeFromCart(_user!.uid, item.itemId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Removed from cart'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQty) async {
    if (_user == null || newQty < 1) return;
    await _cartService.updateQuantity(_user!.uid, item.itemId, newQty);
  }

  void _confirmClear(double width) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_user != null) {
                await _cartService.clearCart(_user!.uid);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}