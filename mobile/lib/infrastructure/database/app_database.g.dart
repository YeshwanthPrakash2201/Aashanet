// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HealthRecordsTable extends HealthRecords
    with TableInfo<$HealthRecordsTable, HealthRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverRecordIdMeta = const VerificationMeta(
    'serverRecordId',
  );
  @override
  late final GeneratedColumn<String> serverRecordId = GeneratedColumn<String>(
    'server_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawInputMeta = const VerificationMeta(
    'rawInput',
  );
  @override
  late final GeneratedColumn<String> rawInput = GeneratedColumn<String>(
    'raw_input',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputLanguageMeta = const VerificationMeta(
    'inputLanguage',
  );
  @override
  late final GeneratedColumn<String> inputLanguage = GeneratedColumn<String>(
    'input_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiStatusMeta = const VerificationMeta(
    'aiStatus',
  );
  @override
  late final GeneratedColumn<String> aiStatus = GeneratedColumn<String>(
    'ai_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_review'),
  );
  static const VerificationMeta _recordStatusMeta = const VerificationMeta(
    'recordStatus',
  );
  @override
  late final GeneratedColumn<String> recordStatus = GeneratedColumn<String>(
    'record_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverRecordId,
    workerId,
    rawInput,
    inputLanguage,
    audioPath,
    aiStatus,
    recordStatus,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_record_id')) {
      context.handle(
        _serverRecordIdMeta,
        serverRecordId.isAcceptableOrUnknown(
          data['server_record_id']!,
          _serverRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    }
    if (data.containsKey('raw_input')) {
      context.handle(
        _rawInputMeta,
        rawInput.isAcceptableOrUnknown(data['raw_input']!, _rawInputMeta),
      );
    } else if (isInserting) {
      context.missing(_rawInputMeta);
    }
    if (data.containsKey('input_language')) {
      context.handle(
        _inputLanguageMeta,
        inputLanguage.isAcceptableOrUnknown(
          data['input_language']!,
          _inputLanguageMeta,
        ),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('ai_status')) {
      context.handle(
        _aiStatusMeta,
        aiStatus.isAcceptableOrUnknown(data['ai_status']!, _aiStatusMeta),
      );
    }
    if (data.containsKey('record_status')) {
      context.handle(
        _recordStatusMeta,
        recordStatus.isAcceptableOrUnknown(
          data['record_status']!,
          _recordStatusMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_record_id'],
      ),
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      ),
      rawInput: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_input'],
      )!,
      inputLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_language'],
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      aiStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_status'],
      )!,
      recordStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_status'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HealthRecordsTable createAlias(String alias) {
    return $HealthRecordsTable(attachedDatabase, alias);
  }
}

class HealthRecord extends DataClass implements Insertable<HealthRecord> {
  final String id;
  final String? serverRecordId;
  final String? workerId;
  final String rawInput;
  final String? inputLanguage;
  final String? audioPath;
  final String aiStatus;
  final String recordStatus;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HealthRecord({
    required this.id,
    this.serverRecordId,
    this.workerId,
    required this.rawInput,
    this.inputLanguage,
    this.audioPath,
    required this.aiStatus,
    required this.recordStatus,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverRecordId != null) {
      map['server_record_id'] = Variable<String>(serverRecordId);
    }
    if (!nullToAbsent || workerId != null) {
      map['worker_id'] = Variable<String>(workerId);
    }
    map['raw_input'] = Variable<String>(rawInput);
    if (!nullToAbsent || inputLanguage != null) {
      map['input_language'] = Variable<String>(inputLanguage);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['ai_status'] = Variable<String>(aiStatus);
    map['record_status'] = Variable<String>(recordStatus);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HealthRecordsCompanion toCompanion(bool nullToAbsent) {
    return HealthRecordsCompanion(
      id: Value(id),
      serverRecordId: serverRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRecordId),
      workerId: workerId == null && nullToAbsent
          ? const Value.absent()
          : Value(workerId),
      rawInput: Value(rawInput),
      inputLanguage: inputLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(inputLanguage),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      aiStatus: Value(aiStatus),
      recordStatus: Value(recordStatus),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HealthRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthRecord(
      id: serializer.fromJson<String>(json['id']),
      serverRecordId: serializer.fromJson<String?>(json['serverRecordId']),
      workerId: serializer.fromJson<String?>(json['workerId']),
      rawInput: serializer.fromJson<String>(json['rawInput']),
      inputLanguage: serializer.fromJson<String?>(json['inputLanguage']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      aiStatus: serializer.fromJson<String>(json['aiStatus']),
      recordStatus: serializer.fromJson<String>(json['recordStatus']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverRecordId': serializer.toJson<String?>(serverRecordId),
      'workerId': serializer.toJson<String?>(workerId),
      'rawInput': serializer.toJson<String>(rawInput),
      'inputLanguage': serializer.toJson<String?>(inputLanguage),
      'audioPath': serializer.toJson<String?>(audioPath),
      'aiStatus': serializer.toJson<String>(aiStatus),
      'recordStatus': serializer.toJson<String>(recordStatus),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HealthRecord copyWith({
    String? id,
    Value<String?> serverRecordId = const Value.absent(),
    Value<String?> workerId = const Value.absent(),
    String? rawInput,
    Value<String?> inputLanguage = const Value.absent(),
    Value<String?> audioPath = const Value.absent(),
    String? aiStatus,
    String? recordStatus,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HealthRecord(
    id: id ?? this.id,
    serverRecordId: serverRecordId.present
        ? serverRecordId.value
        : this.serverRecordId,
    workerId: workerId.present ? workerId.value : this.workerId,
    rawInput: rawInput ?? this.rawInput,
    inputLanguage: inputLanguage.present
        ? inputLanguage.value
        : this.inputLanguage,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    aiStatus: aiStatus ?? this.aiStatus,
    recordStatus: recordStatus ?? this.recordStatus,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HealthRecord copyWithCompanion(HealthRecordsCompanion data) {
    return HealthRecord(
      id: data.id.present ? data.id.value : this.id,
      serverRecordId: data.serverRecordId.present
          ? data.serverRecordId.value
          : this.serverRecordId,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      rawInput: data.rawInput.present ? data.rawInput.value : this.rawInput,
      inputLanguage: data.inputLanguage.present
          ? data.inputLanguage.value
          : this.inputLanguage,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      aiStatus: data.aiStatus.present ? data.aiStatus.value : this.aiStatus,
      recordStatus: data.recordStatus.present
          ? data.recordStatus.value
          : this.recordStatus,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecord(')
          ..write('id: $id, ')
          ..write('serverRecordId: $serverRecordId, ')
          ..write('workerId: $workerId, ')
          ..write('rawInput: $rawInput, ')
          ..write('inputLanguage: $inputLanguage, ')
          ..write('audioPath: $audioPath, ')
          ..write('aiStatus: $aiStatus, ')
          ..write('recordStatus: $recordStatus, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverRecordId,
    workerId,
    rawInput,
    inputLanguage,
    audioPath,
    aiStatus,
    recordStatus,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthRecord &&
          other.id == this.id &&
          other.serverRecordId == this.serverRecordId &&
          other.workerId == this.workerId &&
          other.rawInput == this.rawInput &&
          other.inputLanguage == this.inputLanguage &&
          other.audioPath == this.audioPath &&
          other.aiStatus == this.aiStatus &&
          other.recordStatus == this.recordStatus &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HealthRecordsCompanion extends UpdateCompanion<HealthRecord> {
  final Value<String> id;
  final Value<String?> serverRecordId;
  final Value<String?> workerId;
  final Value<String> rawInput;
  final Value<String?> inputLanguage;
  final Value<String?> audioPath;
  final Value<String> aiStatus;
  final Value<String> recordStatus;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HealthRecordsCompanion({
    this.id = const Value.absent(),
    this.serverRecordId = const Value.absent(),
    this.workerId = const Value.absent(),
    this.rawInput = const Value.absent(),
    this.inputLanguage = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.aiStatus = const Value.absent(),
    this.recordStatus = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthRecordsCompanion.insert({
    required String id,
    this.serverRecordId = const Value.absent(),
    this.workerId = const Value.absent(),
    required String rawInput,
    this.inputLanguage = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.aiStatus = const Value.absent(),
    this.recordStatus = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawInput = Value(rawInput);
  static Insertable<HealthRecord> custom({
    Expression<String>? id,
    Expression<String>? serverRecordId,
    Expression<String>? workerId,
    Expression<String>? rawInput,
    Expression<String>? inputLanguage,
    Expression<String>? audioPath,
    Expression<String>? aiStatus,
    Expression<String>? recordStatus,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverRecordId != null) 'server_record_id': serverRecordId,
      if (workerId != null) 'worker_id': workerId,
      if (rawInput != null) 'raw_input': rawInput,
      if (inputLanguage != null) 'input_language': inputLanguage,
      if (audioPath != null) 'audio_path': audioPath,
      if (aiStatus != null) 'ai_status': aiStatus,
      if (recordStatus != null) 'record_status': recordStatus,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? serverRecordId,
    Value<String?>? workerId,
    Value<String>? rawInput,
    Value<String?>? inputLanguage,
    Value<String?>? audioPath,
    Value<String>? aiStatus,
    Value<String>? recordStatus,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HealthRecordsCompanion(
      id: id ?? this.id,
      serverRecordId: serverRecordId ?? this.serverRecordId,
      workerId: workerId ?? this.workerId,
      rawInput: rawInput ?? this.rawInput,
      inputLanguage: inputLanguage ?? this.inputLanguage,
      audioPath: audioPath ?? this.audioPath,
      aiStatus: aiStatus ?? this.aiStatus,
      recordStatus: recordStatus ?? this.recordStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverRecordId.present) {
      map['server_record_id'] = Variable<String>(serverRecordId.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (rawInput.present) {
      map['raw_input'] = Variable<String>(rawInput.value);
    }
    if (inputLanguage.present) {
      map['input_language'] = Variable<String>(inputLanguage.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (aiStatus.present) {
      map['ai_status'] = Variable<String>(aiStatus.value);
    }
    if (recordStatus.present) {
      map['record_status'] = Variable<String>(recordStatus.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serverRecordId: $serverRecordId, ')
          ..write('workerId: $workerId, ')
          ..write('rawInput: $rawInput, ')
          ..write('inputLanguage: $inputLanguage, ')
          ..write('audioPath: $audioPath, ')
          ..write('aiStatus: $aiStatus, ')
          ..write('recordStatus: $recordStatus, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HealthRecordsTable healthRecords = $HealthRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [healthRecords];
}

typedef $$HealthRecordsTableCreateCompanionBuilder =
    HealthRecordsCompanion Function({
      required String id,
      Value<String?> serverRecordId,
      Value<String?> workerId,
      required String rawInput,
      Value<String?> inputLanguage,
      Value<String?> audioPath,
      Value<String> aiStatus,
      Value<String> recordStatus,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$HealthRecordsTableUpdateCompanionBuilder =
    HealthRecordsCompanion Function({
      Value<String> id,
      Value<String?> serverRecordId,
      Value<String?> workerId,
      Value<String> rawInput,
      Value<String?> inputLanguage,
      Value<String?> audioPath,
      Value<String> aiStatus,
      Value<String> recordStatus,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$HealthRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverRecordId => $composableBuilder(
    column: $table.serverRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputLanguage => $composableBuilder(
    column: $table.inputLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiStatus => $composableBuilder(
    column: $table.aiStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordStatus => $composableBuilder(
    column: $table.recordStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverRecordId => $composableBuilder(
    column: $table.serverRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputLanguage => $composableBuilder(
    column: $table.inputLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiStatus => $composableBuilder(
    column: $table.aiStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordStatus => $composableBuilder(
    column: $table.recordStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverRecordId => $composableBuilder(
    column: $table.serverRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get rawInput =>
      $composableBuilder(column: $table.rawInput, builder: (column) => column);

  GeneratedColumn<String> get inputLanguage => $composableBuilder(
    column: $table.inputLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get aiStatus =>
      $composableBuilder(column: $table.aiStatus, builder: (column) => column);

  GeneratedColumn<String> get recordStatus => $composableBuilder(
    column: $table.recordStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HealthRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthRecordsTable,
          HealthRecord,
          $$HealthRecordsTableFilterComposer,
          $$HealthRecordsTableOrderingComposer,
          $$HealthRecordsTableAnnotationComposer,
          $$HealthRecordsTableCreateCompanionBuilder,
          $$HealthRecordsTableUpdateCompanionBuilder,
          (
            HealthRecord,
            BaseReferences<_$AppDatabase, $HealthRecordsTable, HealthRecord>,
          ),
          HealthRecord,
          PrefetchHooks Function()
        > {
  $$HealthRecordsTableTableManager(_$AppDatabase db, $HealthRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serverRecordId = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String> rawInput = const Value.absent(),
                Value<String?> inputLanguage = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String> aiStatus = const Value.absent(),
                Value<String> recordStatus = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthRecordsCompanion(
                id: id,
                serverRecordId: serverRecordId,
                workerId: workerId,
                rawInput: rawInput,
                inputLanguage: inputLanguage,
                audioPath: audioPath,
                aiStatus: aiStatus,
                recordStatus: recordStatus,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serverRecordId = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                required String rawInput,
                Value<String?> inputLanguage = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String> aiStatus = const Value.absent(),
                Value<String> recordStatus = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthRecordsCompanion.insert(
                id: id,
                serverRecordId: serverRecordId,
                workerId: workerId,
                rawInput: rawInput,
                inputLanguage: inputLanguage,
                audioPath: audioPath,
                aiStatus: aiStatus,
                recordStatus: recordStatus,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HealthRecordsTable, HealthRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HealthRecordsTable,
                    HealthRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthRecordsTable,
      HealthRecord,
      $$HealthRecordsTableFilterComposer,
      $$HealthRecordsTableOrderingComposer,
      $$HealthRecordsTableAnnotationComposer,
      $$HealthRecordsTableCreateCompanionBuilder,
      $$HealthRecordsTableUpdateCompanionBuilder,
      (
        HealthRecord,
        BaseReferences<_$AppDatabase, $HealthRecordsTable, HealthRecord>,
      ),
      HealthRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HealthRecordsTableTableManager get healthRecords =>
      $$HealthRecordsTableTableManager(_db, _db.healthRecords);
}
