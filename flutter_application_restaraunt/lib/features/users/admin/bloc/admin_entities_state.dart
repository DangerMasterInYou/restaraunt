part of 'admin_entities_bloc.dart';

abstract class AdminEntitiesState {}

class AdminEntitiesInitial extends AdminEntitiesState {}

class AdminEntitiesLoading extends AdminEntitiesState {}

class AdminEntitiesLoaded extends AdminEntitiesState {
  final List<CategoryResponse> categories;
  final List<ProductResponse> products;
  final List<VariantResponse> variants;
  final List<ModifierResponse> modifiers;
  final List<ModifierGroupResponse> modifierGroups;
  AdminEntitiesLoaded({
    required this.categories,
    required this.products,
    required this.variants,
    required this.modifiers,
    required this.modifierGroups,
  });
}

class AdminEntitiesError extends AdminEntitiesState {
  final String message;
  AdminEntitiesError(this.message);
}

class AdminEntityOperationLoading extends AdminEntitiesState {}

class AdminEntityOperationSuccess extends AdminEntitiesState {}

class AdminEntityOperationError extends AdminEntitiesState {
  final String message;
  AdminEntityOperationError(this.message);
}
