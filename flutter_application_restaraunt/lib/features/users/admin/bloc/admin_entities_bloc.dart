import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_restaraunt/core/repositories/users/admin/restaraunt/product_full/product_full.dart';
import 'package:get_it/get_it.dart';

part 'admin_entities_state.dart';
part 'admin_entities_event.dart';

class AdminEntitiesBloc extends Bloc<AdminEntitiesEvent, AdminEntitiesState> {
  final CategoriesRepository categoriesRepository;
  final ProductRepository productRepository;
  final ProductVariantRepository variantRepository;
  final ModifierRepository modifierRepository;
  final ModifierGroupRepository modifierGroupRepository;
  final ModifierGroupAssociationRepository associationRepository;

  AdminEntitiesBloc()
      : categoriesRepository = GetIt.I<CategoriesRepository>(),
        productRepository = GetIt.I<ProductRepository>(),
        variantRepository = GetIt.I<ProductVariantRepository>(),
        modifierRepository = GetIt.I<ModifierRepository>(),
        modifierGroupRepository = GetIt.I<ModifierGroupRepository>(),
        associationRepository = GetIt.I<ModifierGroupAssociationRepository>(),
        super(AdminEntitiesInitial()) {
    on<LoadAllEntities>(_onLoadAll);

    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<RestoreCategory>(_onRestoreCategory);

    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<RestoreProduct>(_onRestoreProduct);

    on<CreateVariant>(_onCreateVariant);
    on<UpdateVariant>(_onUpdateVariant);
    on<DeleteVariant>(_onDeleteVariant);
    on<RestoreVariant>(_onRestoreVariant);

    on<CreateModifier>(_onCreateModifier);
    on<UpdateModifier>(_onUpdateModifier);
    on<DeleteModifier>(_onDeleteModifier);
    on<RestoreModifier>(_onRestoreModifier);

    on<CreateModifierGroup>(_onCreateModifierGroup);
    on<UpdateModifierGroup>(_onUpdateModifierGroup);
    on<DeleteModifierGroup>(_onDeleteModifierGroup);
    on<RestoreModifierGroup>(_onRestoreModifierGroup);

    on<LinkGroupToVariant>(_onLinkGroupToVariant);
    on<UnlinkGroupFromVariant>(_onUnlinkGroupFromVariant);
    on<UpdateVariantModifierGroups>(_onUpdateVariantModifierGroups);
    on<UpdateProductModifierGroups>(_onUpdateProductModifierGroups);
    on<CreateCombo>(_onCreateCombo);
    on<ReorderCategories>(_onReorderCategories);
    on<ReorderProducts>(_onReorderProducts);
  }

  Future<void> _onReorderCategories(
      ReorderCategories event, Emitter<AdminEntitiesState> emit) async {
    try {
      await categoriesRepository.reorderCategories(event.ids);
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
    }
    add(LoadAllEntities());
  }

  Future<void> _onReorderProducts(
      ReorderProducts event, Emitter<AdminEntitiesState> emit) async {
    try {
      await productRepository.reorderProducts(event.ids);
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
    }
    add(LoadAllEntities());
  }

  Future<void> _onLoadAll(
      LoadAllEntities event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntitiesLoading());
    try {
      final categories = await categoriesRepository.getCategoryList();
      final products = await productRepository.getProductList();
      final variants = await variantRepository.getProductVariantList();
      final modifiers = await modifierRepository.getModifierList();
      final modifierGroups =
          await modifierGroupRepository.getModifierGroupList();
      emit(AdminEntitiesLoaded(
        categories: categories,
        products: products,
        variants: variants,
        modifiers: modifiers,
        modifierGroups: modifierGroups,
      ));
    } catch (e) {
      emit(AdminEntitiesError(e.toString()));
    }
  }

  Future<void> _onCreateCategory(
      CreateCategory event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await categoriesRepository.postCreateCategory(
        CategoryCreateDTO(name: event.name, sortOrder: event.sortOrder),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onUpdateCategory(
      UpdateCategory event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await categoriesRepository.patchCategory(
        event.id,
        CategoryPatchDTO(name: event.name, sortOrder: event.sortOrder),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      if (event.hard) {
        await categoriesRepository.deleteHardCategory(event.id);
      } else {
        await categoriesRepository.deleteSoftCategory(event.id);
      }
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onRestoreCategory(
      RestoreCategory event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await categoriesRepository.postRestoreCategory(event.id);
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onCreateProduct(
      CreateProduct event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await productRepository.postCreateProduct(
        ProductCreateDTO(
          categoryId: event.categoryId,
          name: event.name,
          description: event.description,
          sortOrder: event.sortOrder,
          imageUrl: event.imageUrl,
        ),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await productRepository.patchProduct(
        event.id,
        ProductPatchDTO(
          categoryId: event.categoryId,
          name: event.name,
          description: event.description,
          sortOrder: event.sortOrder,
          imageUrl: event.imageUrl,
        ),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onDeleteProduct(
      DeleteProduct event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      if (event.hard) {
        await productRepository.deleteHardProduct(event.id);
      } else {
        await productRepository.deleteSoftProduct(event.id);
      }
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onRestoreProduct(
      RestoreProduct event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await productRepository.postRestoreProduct(event.id);
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onCreateVariant(
      CreateVariant event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await variantRepository.postCreateProductVariant(
        ProductVariantCreateDTO(
          name: event.name,
          price: event.price,
          productId: event.productId,
          sku: event.sku,
          isAvailable: event.isAvailable,
          isCombo: event.isCombo,
          imageUrl: event.imageUrl,
          value: event.value,
          unit: event.unit,
        ),
        event.productId,
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onUpdateVariant(
      UpdateVariant event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await variantRepository.patchProductVariant(
        event.id,
        ProductVariantPatchDTO(
          name: event.name,
          price: event.price,
          imageUrl: event.imageUrl,
          sku: event.sku,
          isAvailable: event.isAvailable,
          isCombo: event.isCombo,
          value: event.value,
          unit: event.unit,
        ),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onDeleteVariant(
      DeleteVariant event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      if (event.hard) {
        await variantRepository.deleteHardProductVariant(event.id);
      } else {
        await variantRepository.deleteSoftProductVariant(event.id);
      }
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onRestoreVariant(
      RestoreVariant event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await variantRepository.postRestoreProductVariant(event.id);
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onCreateModifier(
      CreateModifier event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await modifierRepository.postCreateModifier(
        event.groupId,
        ModifierCreateDTO(
            name: event.name,
            priceDelta: event.price,
            imageUrl: event.imageUrl),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onUpdateModifier(
      UpdateModifier event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await modifierRepository.patchModifier(
        event.id,
        ModifierPatchDTO(
            name: event.name,
            priceDelta: event.price,
            imageUrl: event.imageUrl),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onDeleteModifier(
      DeleteModifier event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      if (event.hard) {
        await modifierRepository.deleteHardModifier(event.id);
      } else {
        await modifierRepository.deleteSoftModifier(event.id);
      }
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onRestoreModifier(
      RestoreModifier event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await modifierRepository.postRestoreModifier(event.id);
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onCreateModifierGroup(
      CreateModifierGroup event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await modifierGroupRepository.postCreateModifierGroup(
        ModifierGroupCreateDTO(
          name: event.name,
          isRequired: event.isRequired,
          isMultiselect: event.isMultiselect,
        ),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onUpdateModifierGroup(
      UpdateModifierGroup event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await modifierGroupRepository.patchModifierGroup(
        event.id,
        ModifierGroupPatchDTO(
          name: event.name,
          isRequired: event.isRequired,
          isMultiselect: event.isMultiselect,
        ),
      );
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onDeleteModifierGroup(
      DeleteModifierGroup event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      if (event.hard) {
        await modifierGroupRepository.deleteHardModifierGroup(event.id);
      } else {
        await modifierGroupRepository.deleteSoftModifierGroup(event.id);
      }
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onRestoreModifierGroup(
      RestoreModifierGroup event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await modifierGroupRepository.postRestoreModifierGroup(event.id);
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onLinkGroupToVariant(
      LinkGroupToVariant event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await associationRepository.linkGroupToVariant(
          event.variantId, event.groupId);
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onUnlinkGroupFromVariant(
      UnlinkGroupFromVariant event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      await associationRepository.unlinkGroupFromVariant(
          event.variantId, event.groupId);
      emit(AdminEntityOperationSuccess());
      add(LoadAllEntities());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
      add(LoadAllEntities());
    }
  }

  Future<void> _onUpdateVariantModifierGroups(
      UpdateVariantModifierGroups event,
      Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {

      for (final groupId in event.groupIdsToUnlink) {
        await associationRepository.unlinkGroupFromVariant(
            event.variantId, groupId);
      }
      for (final groupId in event.groupIdsToLink) {
        await associationRepository.linkGroupToVariant(
            event.variantId, groupId);
      }
      emit(AdminEntityOperationSuccess());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
    }
    add(LoadAllEntities());
  }

  Future<void> _onCreateCombo(
      CreateCombo event, Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {

      final categories = await categoriesRepository.getCategoryList();
      int comboCategoryId;
      final existing =
          categories.where((c) => c.name == 'Комбо').toList();
      if (existing.isNotEmpty) {
        comboCategoryId = existing.first.id;
      } else {
        final created = await categoriesRepository.postCreateCategory(
          CategoryCreateDTO(name: 'Комбо', sortOrder: 99),
        );
        comboCategoryId = created.id;
      }

      final product = await productRepository.postCreateProduct(
        ProductCreateDTO(
          categoryId: comboCategoryId,
          name: event.name,
          description: 'Комбо-набор',
          sortOrder: 0,
          imageUrl: event.imageUrl ?? '',
        ),
      );

      await variantRepository.postCreateProductVariant(
        ProductVariantCreateDTO(
          name: 'Стандарт',
          price: event.price,
          productId: product.id,
          sku: 'CMB-${product.id}',
          isAvailable: true,
          isCombo: true,
          imageUrl: event.imageUrl,
        ),
        product.id,
      );
      emit(AdminEntityOperationSuccess());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
    }
    add(LoadAllEntities());
  }

  Future<void> _onUpdateProductModifierGroups(
      UpdateProductModifierGroups event,
      Emitter<AdminEntitiesState> emit) async {
    emit(AdminEntityOperationLoading());
    try {
      for (final groupId in event.groupIdsToUnlink) {
        await associationRepository.unlinkGroupFromProduct(
            event.productId, groupId);
      }
      for (final groupId in event.groupIdsToLink) {
        await associationRepository.linkGroupToProduct(
            event.productId, groupId);
      }
      emit(AdminEntityOperationSuccess());
    } catch (e) {
      emit(AdminEntityOperationError(e.toString()));
    }
    add(LoadAllEntities());
  }
}
