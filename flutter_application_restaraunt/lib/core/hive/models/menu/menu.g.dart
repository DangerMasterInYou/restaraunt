// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuAdapter extends TypeAdapter<Menu> {
  @override
  final int typeId = 2;

  @override
  Menu read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Menu(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String?,
      imageUrl: fields[3] as String?,
      category: fields[4] as String,
      price: fields[5] as int,
      value: fields[6] as int?,
      unit: fields[7] as String?,
      sku: fields[8] as String,
      isAvailable: fields[9] as bool,
      isDeleted: fields[10] as bool?,
      modifierGroups: (fields[11] as List).cast<ModifierGroup>(),
      productId: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Menu obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.value)
      ..writeByte(7)
      ..write(obj.unit)
      ..writeByte(8)
      ..write(obj.sku)
      ..writeByte(9)
      ..write(obj.isAvailable)
      ..writeByte(10)
      ..write(obj.isDeleted)
      ..writeByte(11)
      ..write(obj.modifierGroups)
      ..writeByte(12)
      ..write(obj.productId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ModifierGroupAdapter extends TypeAdapter<ModifierGroup> {
  @override
  final int typeId = 3;

  @override
  ModifierGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModifierGroup(
      id: fields[0] as int,
      name: fields[1] as String,
      isRequired: fields[2] as bool,
      isMultiselect: fields[3] as bool,
      isDeleted: fields[4] as bool,
      modifiers: (fields[5] as List).cast<Modifier>(),
    );
  }

  @override
  void write(BinaryWriter writer, ModifierGroup obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isRequired)
      ..writeByte(3)
      ..write(obj.isMultiselect)
      ..writeByte(4)
      ..write(obj.isDeleted)
      ..writeByte(5)
      ..write(obj.modifiers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifierGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ModifierAdapter extends TypeAdapter<Modifier> {
  @override
  final int typeId = 4;

  @override
  Modifier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Modifier(
      id: fields[0] as int,
      name: fields[1] as String,
      priceDelta: fields[2] as int,
      imageUrl: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Modifier obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.priceDelta)
      ..writeByte(3)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Menu _$MenuFromJson(Map<String, dynamic> json) => Menu(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String,
      price: (json['price'] as num).toInt(),
      value: (json['value'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      sku: json['sku'] as String,
      isAvailable: json['is_available'] as bool,
      isDeleted: json['is_deleted'] as bool? ?? false,
      modifierGroups: (json['modifier_groups'] as List<dynamic>)
          .map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      productId: (json['product_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MenuToJson(Menu instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'category': instance.category,
      'price': instance.price,
      'value': instance.value,
      'unit': instance.unit,
      'sku': instance.sku,
      'is_available': instance.isAvailable,
      'is_deleted': instance.isDeleted,
      'modifier_groups': instance.modifierGroups,
      'product_id': instance.productId,
    };

ModifierGroup _$ModifierGroupFromJson(Map<String, dynamic> json) =>
    ModifierGroup(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isRequired: json['is_required'] as bool,
      isMultiselect: json['is_multiselect'] as bool,
      isDeleted: json['is_deleted'] as bool? ?? false,
      modifiers: (json['modifiers'] as List<dynamic>)
          .map((e) => Modifier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ModifierGroupToJson(ModifierGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_required': instance.isRequired,
      'is_multiselect': instance.isMultiselect,
      'is_deleted': instance.isDeleted,
      'modifiers': instance.modifiers,
    };

Modifier _$ModifierFromJson(Map<String, dynamic> json) => Modifier(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      priceDelta: (json['price_delta'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$ModifierToJson(Modifier instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price_delta': instance.priceDelta,
      'image_url': instance.imageUrl,
    };
