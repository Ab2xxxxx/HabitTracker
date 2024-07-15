import 'package:flutter/material.dart';
import 'package:habit_tracker/models/app_settings.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier{

  static late Isar isar;

  static Future<void> initialize() async{
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [HabitSchema, AppSettingsSchema], 
      directory: dir.path
    );
  }

  Future<void> saveFirstlaunchDate() async{
    final exitingSetting = await isar.appSettings.where().findFirst();
    if(exitingSetting == null){
      final setting = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(setting));
    }
  }

  Future<DateTime?> getFirstLaunchDate() async{
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }


  final List<Habit> currentHabits = [];

  Future<void> addHabits(String habitName) async{
    final newHabit = Habit()..name = habitName;
    await isar.writeTxn(() => isar.habits.put(newHabit));
    readHabits();
  }

  Future<void> readHabits() async{
    List<Habit> fetchedHabits = await isar.habits.where().findAll();
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    notifyListeners();
  }

  Future<void> updateHabitCompletion(int id, bool isCompleted) async{
    final habit = await isar.habits.get(id);
    if(habit != null){
      await isar.writeTxn(()async{
        if (isCompleted && !habit.completedDays.contains(DateTime.now())){
          final today = DateTime.now();

          habit.completedDays.add(
            DateTime(
              today.year,
              today.month,
              today.day,
            )
          );
        } else{
          habit.completedDays.removeWhere(
            (data) =>
              data.year == DateTime.now().year &&
              data.month == DateTime.now().month &&
              data.day == DateTime.now().day
          );
        }
        await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  Future<void> updateHabitName(int id, String newName) async{
    final habit = await isar.habits.get(id);

    if (habit != null){
      await isar.writeTxn(() async{
        habit.name = newName;
        await isar.habits.put(habit);
      });
    }

    readHabits();
  }

  Future<void> deleteHabit(int id) async{
    await isar.writeTxn(() async{
      await isar.habits.delete(id);
    });

    readHabits();
  }
  

}