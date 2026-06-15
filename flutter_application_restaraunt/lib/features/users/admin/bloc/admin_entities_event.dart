part of 'admin_entities_bloc.dart';

abstract class AdminEntitiesEvent extends Equatable {
  const AdminEntitiesEvent();
  @override
  List<Object?> get props => [];
}

class LoadAllEntities extends AdminEntitiesEvent {}

class CreateCategory extends AdminEntitiesEvent {
  final String name;
  final int sortOrder;
  const CreateCategory({required this.name, required this.sortOrder});
  @override
  List<Object?> get props => [name, sortOrder];
}

class UpdateCategory extends AdminEntitiesEvent {
  final int id;
  final String? name;
  final int? sortOrder;
  const UpdateCategory({required this.id, this.name, this.sortOrder});
  @override
  List<Object?> get props => [id, name, sortOrder];
}

class DeleteCategory extends AdminEntitiesEvent {
  final int id;
  final bool hard;
  const DeleteCategory({required this.id, this.hard = false});
  @override
  List<Object?> get props => [id, hard];
}

class RestoreCategory extends AdminEntitiesEvent {
  final int id;
  const RestoreCategory({required this.id});
  @override
  List<Object?> get props => [id];
}

class CreateProduct extends AdminEntitiesEvent {
  final int categoryId;
  final String name;
  final String? description;
  final int sortOrder;
  final String imageUrl;
  const CreateProduct({
    required this.categoryId,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.imageUrl,
  });
  @override
  List<Object?> get props =>
      [categoryId, name, description, sortOrder, imageUrl];
}

class UpdateProduct extends AdminEntitiesEvent {
  final int id;
  final int? categoryId;
  final String? name;
  final String? description;
  final int? sortOrder;
  final String? imageUrl;
  const UpdateProduct({
    required this.id,
    this.categoryId,
    this.name,
    this.description,
    this.sortOrder,
    this.imageUrl,
  });
  @override
  List<Object?> get props =>
      [id, categoryId, name, description, sortOrder, imageUrl];
}

class DeleteProduct extends AdminEntitiesEvent {
  final int id;
  final bool hard;
  const DeleteProduct({required this.id, this.hard = false});
  @override
  List<Object?> get props => [id, hard];
}

class RestoreProduct extends AdminEntitiesEvent {
  final int id;
  const RestoreProduct({required this.id});
  @override
  List<Object?> get props => [id];
}

class CreateVariant extends AdminEntitiesEvent {
  final int productId;
  final String name;
  final int price;
  final String sku;
  final bool isAvailable;
  final bool isCombo;
  final String? imageUrl;
  final int? value;
  final String? unit;
  const CreateVariant({
    required this.productId,
    required this.name,
    required this.price,
    required this.sku,
    required this.isAvailable,
    required this.isCombo,
    this.imageUrl,
    this.value,
    this.unit,
  });
  @override
  List<Object?> get props =>
      [productId, name, price, sku, isAvailable, isCombo, imageUrl, value, unit];
}

class UpdateVariant extends AdminEntitiesEvent {
  final int id;
  final String? name;
  final int? price;
  final String? imageUrl;
  final String? sku;
  final bool? isAvailable;
  final bool? isCombo;
  final int? value;
  final String? unit;
  const UpdateVariant({
    required this.id,
    this.name,
    this.price,
    this.imageUrl,
    this.sku,
    this.isAvailable,
    this.isCombo,
    this.value,
    this.unit,
  });
  @override
  List<Object?> get props =>
      [id, name, price, imageUrl, sku, isAvailable, isCombo, value, unit];
}

class DeleteVariant extends AdminEntitiesEvent {
  final int id;
  final bool hard;
  const DeleteVariant({required this.id, this.hard = false});
  @override
  List<Object?> get props => [id, hard];
}

class RestoreVariant extends AdminEntitiesEvent {
  final int id;
  const RestoreVariant({required this.id});
  @override
  List<Object?> get props => [id];
}

class CreateModifier extends AdminEntitiesEvent {
  final String name;
  final int price;
  final int groupId;
  final String? imageUrl;
  const CreateModifier(
      {required this.name,
      required this.price,
      required this.groupId,
      this.imageUrl});
  @override
  List<Object?> get props => [name, price, groupId, imageUrl];
}

class UpdateModifier extends AdminEntitiesEvent {
  final int id;
  final String? name;
  final int? price;
  final int groupId;
  final String? imageUrl;
  const UpdateModifier(
      {required this.id,
      this.name,
      this.price,
      required this.groupId,
      this.imageUrl});
  @override
  List<Object?> get props => [id, name, price, groupId, imageUrl];
}

class DeleteModifier extends AdminEntitiesEvent {
  final int id;
  final bool hard;
  const DeleteModifier({required this.id, this.hard = false});
  @override
  List<Object?> get props => [id, hard];
}

class RestoreModifier extends AdminEntitiesEvent {
  final int id;
  const RestoreModifier({required this.id});
  @override
  List<Object?> get props => [id];
}

class CreateModifierGroup extends AdminEntitiesEvent {
  final String name;
  final bool isRequired;
  final bool isMultiselect;
  const CreateModifierGroup({
    required this.name,
    required this.isRequired,
    required this.isMultiselect,
  });
  @override
  List<Object?> get props => [name, isRequired, isMultiselect];
}

class UpdateModifierGroup extends AdminEntitiesEvent {
  final int id;
  final String? name;
  final bool? isRequired;
  final bool? isMultiselect;
  const UpdateModifierGroup({
    required this.id,
    this.name,
    this.isRequired,
    this.isMultiselect,
  });
  @override
  List<Object?> get props => [id, name, isRequired, isMultiselect];
}

class DeleteModifierGroup extends AdminEntitiesEvent {
  final int id;
  final bool hard;
  const DeleteModifierGroup({required this.id, this.hard = false});
  @override
  List<Object?> get props => [id, hard];
}

class RestoreModifierGroup extends AdminEntitiesEvent {
  final int id;
  const RestoreModifierGroup({required this.id});
  @override
  List<Object?> get props => [id];
}

class LinkGroupToVariant extends AdminEntitiesEvent {
  final int variantId;
  final int groupId;
  const LinkGroupToVariant({required this.variantId, required this.groupId});
  @override
  List<Object?> get props => [variantId, groupId];
}

class UnlinkGroupFromVariant extends AdminEntitiesEvent {
  final int variantId;
  final int groupId;
  const UnlinkGroupFromVariant(
      {required this.variantId, required this.groupId});
  @override
  List<Object?> get props => [variantId, groupId];
}

class UpdateVariantModifierGroups extends AdminEntitiesEvent {
  final int variantId;
  final List<int> groupIdsToLink;
  final List<int> groupIdsToUnlink;
  const UpdateVariantModifierGroups({
    required this.variantId,
    required this.groupIdsToLink,
    required this.groupIdsToUnlink,
  });
  @override
  List<Object?> get props => [variantId, groupIdsToLink, groupIdsToUnlink];
}

class ReorderCategories extends AdminEntitiesEvent {
  final List<int> ids;
  const ReorderCategories(this.ids);
  @override
  List<Object?> get props => [ids];
}

class ReorderProducts extends AdminEntitiesEvent {
  final List<int> ids;
  const ReorderProducts(this.ids);
  @override
  List<Object?> get props => [ids];
}

class CreateCombo extends AdminEntitiesEvent {
  final String name;
  final int price;
  final String? imageUrl;
  const CreateCombo({required this.name, required this.price, this.imageUrl});
  @override
  List<Object?> get props => [name, price, imageUrl];
}

class UpdateProductModifierGroups extends AdminEntitiesEvent {
  final int productId;
  final List<int> groupIdsToLink;
  final List<int> groupIdsToUnlink;
  const UpdateProductModifierGroups({
    required this.productId,
    required this.groupIdsToLink,
    required this.groupIdsToUnlink,
  });
  @override
  List<Object?> get props => [productId, groupIdsToLink, groupIdsToUnlink];
}
