mixin IPartRoute {
  bool acceptPart({required String part});
  void addValue({required String part,required Map<String, dynamic> namedValues});
}
