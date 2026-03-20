import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart.dart';

abstract class CartRepository {
  Future<Either<Failure, Cart>> getCart();
  Future<Either<Failure, Cart>> addItem({required String productId, int quantity = 1});
  Future<Either<Failure, Cart>> updateQuantity({required String itemId, required int quantity});
  Future<Either<Failure, Cart>> removeItem(String itemId);
  Future<Either<Failure, Cart>> applyCoupon(String code);
  Future<Either<Failure, Cart>> removeCoupon();
  Future<Either<Failure, void>> clearCart();
}
