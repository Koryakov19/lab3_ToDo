import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? taskList = prefs.getStringList('tasks');
  List<Task> tasks = taskList != null
      ? taskList.map((taskJson) => Task.fromJson(jsonDecode(taskJson))).toList()
      : [];
  runApp(TodoApp(tasks: tasks));
}

class TodoApp extends StatelessWidget {
  final List<Task> tasks;

  TodoApp({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(tasks: tasks),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  final List<Task> tasks;

  TodoListScreen({required this.tasks});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late List<Task> tasks;
  String filterType = 'all';

  @override
  void initState() {
    super.initState();
    tasks = widget.tasks;
  }

  void setFilter(String type) {
    setState(() {
      filterType = type;
    });
  }

  List<Task> getFilteredTasks() {
    if (filterType == 'all') {
      return tasks;
    } else if (filterType == 'current') {
      return tasks.where((task) => !task.completed).toList();
    } else { // completed
      return tasks.where((task) => task.completed).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Task> displayedTasks = getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: Column(
        children: [
          FilterButtons(onFilterSelected: setFilter),
          Expanded(
            child: displayedTasks.isEmpty
                ? Center(child: Text('No tasks scheduled'))
                : ListView.builder(
              itemCount: displayedTasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(displayedTasks[index].title),
                  subtitle: Text('${displayedTasks[index].description}\nDue: ${DateFormat('yyyy-MM-dd – HH:mm').format(displayedTasks[index].dueDate)}'),
                  trailing: displayedTasks[index].completed
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    setState(() {
                      displayedTasks[index].completed = !displayedTasks[index].completed;
                      saveTasks(tasks);
                    });
                  },
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskScreen(
                          task: displayedTasks[index],
                          onUpdate: (updatedTask) {
                            setState(() {
                              int idx = tasks.indexOf(displayedTasks[index]);
                              tasks[idx] = updatedTask;
                              saveTasks(tasks);
                            });
                          },
                          onDelete: () {
                            setState(() {
                              tasks.removeAt(tasks.indexOf(displayedTasks[index]));
                              saveTasks(tasks);
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(
                onAdd: (newTask) {
                  setState(() {
                    tasks.add(newTask);
                    saveTasks(tasks);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> saveTasks(List<Task> tasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', taskList);
  }
}

class Task {
  String title;
  String description;
  DateTime dueDate;
  bool completed;

  Task({
    required this.title,
    this.description = '',
    required this.dueDate,
    this.completed = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      completed: json['completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed,
    };
  }
}

class FilterButtons extends StatelessWidget {
  final Function(String) onFilterSelected;

  FilterButtons({required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('All'),
          onPressed: () => onFilterSelected('all'),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          child: Text('Current'),
          onPressed: () => onFilterSelected('current'),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          child: Text('Completed'),
          onPressed: () => onFilterSelected('completed'),
        ),
      ],
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  final Function(Task) onAdd;

  AddTaskScreen({required this.onAdd});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2025),
                );
                if (picked != null && picked != selectedDate)
                  selectedDate = picked;
              },
              child: Text('Select Due Date'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final task = Task(
                  title: titleController.text,
                  description: descriptionController.text,
                  dueDate: selectedDate,
                );
                onAdd(task);
                Navigator.pop(context);
              },
              child: Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;
  final Function(Task) onUpdate;
  final VoidCallback onDelete;

  EditTaskScreen({
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    titleController.text = task.title;
    descriptionController.text = task.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  title: titleController.text,
                  description: descriptionController.text,
                  dueDate: task.dueDate,
                  completed: task.completed,
                );
                onUpdate(updatedTask);
                Navigator.pop(context);
              },
              child: Text('Update Task'),
            ),
          ],
        ),
      ),
    );
  }
}