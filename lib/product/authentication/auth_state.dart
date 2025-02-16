class AuthState {
  final bool isLoading;
  AuthState({this.isLoading = false});

  AuthState copyWith({bool? isLoading}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
