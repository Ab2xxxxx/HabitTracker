import 'package:flutter/material.dart';
import 'package:habit_tracker/components/my_drawer.dart';
import 'package:habit_tracker/components/my_habit_tile.dart';
import 'package:habit_tracker/components/my_heat_map.dart';
import 'package:habit_tracker/database/habit_database.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/util/habit_util.dart';
import 'package:provider/provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {  

  @override
  void initState() {
    Provider.of<HabitDatabase>(context, listen: false).readHabits();
    super.initState();
  }

  final TextEditingController textController = TextEditingController();

  void createNewHabit(){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: "Create a new habit"),
        ),
        actions: [
          MaterialButton(onPressed: (){
            String newHabitName = textController.text;
            context.read<HabitDatabase>().addHabits(newHabitName);
            Navigator.pop(context);
            textController.clear();
          },
            child: const Text("Save"),
          ),

          MaterialButton(onPressed: (){
            Navigator.pop(context);
            textController.clear();
          },
            child: const Text("Cancel"),
          ),
        ],
      )
    );
  }

  void checkHabitOnOff(bool? value, Habit habit){
    if(value != null){
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  void editHabitBox(Habit habit){
    textController.text = habit.name;

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
        ),
        actions: [
          MaterialButton(onPressed: (){
            String newHabitName = textController.text;
            context.read<HabitDatabase>().updateHabitName(habit.id, newHabitName);
            Navigator.pop(context);
            textController.clear();
          },
            child: const Text("Save"),
          ),

          MaterialButton(onPressed: (){
            Navigator.pop(context);
            textController.clear();
          },
            child: const Text("Cancel"),
          ),
        ],
      )
    );
  }

  void deleteHabitBox(Habit habit){
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Are you sure you want to delete?"),
        actions: [
          MaterialButton(onPressed: (){
            context.read<HabitDatabase>().deleteHabit(habit.id);
            Navigator.pop(context);
          },
            child: const Text("Delete"),
          ),

          MaterialButton(onPressed: (){
            Navigator.pop(context);
          },
            child: const Text("Cancel"),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListView(
        children: [
          _buildHeatMap(),
          _buildHabitList()
        ],
      ),
    );
  }

  Widget _buildHabitList(){
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;
    return ListView.builder(
      itemCount: currentHabits.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index){
        final habit = currentHabits[index];
        bool isCompletedToday = isHabitCompletedToday(habit.completedDays);
        return MyHabitTile(
          isCompleted: isCompletedToday, 
          name: habit.name, 
          onChanged: (value) => checkHabitOnOff(value, habit),
          editHabit: (context) => editHabitBox(habit),
          deleteHabit: (context) => deleteHabitBox(habit),
        );
      }
    );
  }

  Widget _buildHeatMap(){
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;
    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(), 
      builder: (context, snapshot){
        if(snapshot.hasData){
          return MyHeatMap(
            startDate: snapshot.data!, 
            datasets: prepHeatMapDataset(currentHabits),
          );
        } else{
          return Container();
        }
      }
    );
  }

}