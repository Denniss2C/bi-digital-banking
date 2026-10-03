import 'package:equatable/equatable.dart';

/// Signed-in customer, independent of the auth provider.
class AppUser extends Equatable {
  const AppUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  @override
  List<Object?> get props => [id, email, displayName];
}
