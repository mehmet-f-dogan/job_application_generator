import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_application_generator/handlers/email_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Application Generator',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String outputDir = "/home/\$USER";
  String emailTemplate = "";
  List<String> emailTemplatePlaceholders = [];
  Map<String, String> emailTemplatePlaceholderReplacementMap = {};

  String htmlTemplate = "|CONTENT|";
  String coverLetterTemplate = "";
  String institutionName = "";
  Directory? coverLetterTemplateDirectory;
  List<String> coverLetterPlaceholders = [];
  Map<String, String> coverLetterPlaceholderReplacementMap = {};

  Future<String?> selectOutputDirectory() {
    return Future(() async {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        return selectedDirectory;
      }
    }).onError((error, stackTrace) {
      return "/";
    });
  }

  Future<String> loadTemplate() async {
    return Future(() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        return file.readAsStringSync();
      } else {
        return "";
      }
    }).onError((error, stackTrace) {
      return "";
    });
  }

  Future<String> loadCoverLetterTemplate() async {
    return Future(() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        coverLetterTemplateDirectory = file.parent;
        return file.readAsStringSync();
      } else {
        return "";
      }
    }).onError((error, stackTrace) {
      return "";
    });
  }

  List<String> extractPlaceholders(String template) {
    Set<String> placeholders = <String>{};
    List<int> indices = [];
    for (var i = 0; i < template.length; i++) {
      if (template[i] == "|") {
        indices.add(i);
      }
    }
    for (var i = 0; i < indices.length; i += 2) {
      placeholders.add(template.substring(indices[i], indices[i + 1] + 1));
    }

    return placeholders.toList();
  }

  String replacePlaceholders(
      String template, Map<String, String> replacements) {
    String returnString = template.toString();
    for (var key in replacements.keys) {
      returnString = returnString.replaceAll(key, replacements[key]!);
    }
    return returnString;
  }

  void setEmailPlaceholders(List<String> placeholders) {
    setState(() {
      emailTemplatePlaceholders = placeholders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () {
                        loadTemplate().then((value) {
                          emailTemplate = value;
                          setState(() {
                            emailTemplatePlaceholders =
                                extractPlaceholders(emailTemplate);
                          });
                        });
                      },
                      child: const Text("Email Template")),
                  TextButton(
                      onPressed: () {
                        loadTemplate().then((value) => htmlTemplate = value);
                      },
                      child: const Text("HTML Template")),
                  TextButton(
                      onPressed: () {
                        loadCoverLetterTemplate().then((value) {
                          coverLetterTemplate = value;
                          setState(() {
                            coverLetterPlaceholders =
                                extractPlaceholders(coverLetterTemplate);
                          });
                        });
                      },
                      child: const Text("Cover Letter Template")),
                  TextButton(
                      onPressed: () {
                        selectOutputDirectory()
                            .then((value) => outputDir = value!);
                      },
                      child: const Text("Select Output Directory")),
                  TextButton(
                      onPressed: () async {
                        String processedHtml = EmailHandler.replacePlaceholders(
                            htmlTemplate,
                            replacePlaceholders(emailTemplate,
                                emailTemplatePlaceholderReplacementMap));
                        Clipboard.setData(ClipboardData(text: processedHtml));
                        String processedTex = replacePlaceholders(
                            coverLetterTemplate,
                            coverLetterPlaceholderReplacementMap);
                        String dirName =
                            '$outputDir/$institutionName - ${DateTime.now().microsecondsSinceEpoch.toString()}';
                        Directory(dirName).createSync();

                        await File("$dirName/email.html")
                            .create()
                            .then((value) =>
                                value.writeAsStringSync(processedHtml))
                            .onError((error, stackTrace) {});
                        await File("$dirName/cover_letter.tex")
                            .create()
                            .then((value) =>
                                value.writeAsStringSync(processedTex))
                            .onError((error, stackTrace) {});
                      },
                      child: const Text("Complete")),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  institutionName = value;
                },
              ),
            ),
            Expanded(
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ...emailTemplatePlaceholders.map((e) {
                                      return TextField(
                                        decoration: InputDecoration(
                                          hintText: e,
                                        ),
                                        onChanged: (value) {
                                          emailTemplatePlaceholderReplacementMap[
                                              e] = value;
                                        },
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ...coverLetterPlaceholders.map((e) {
                                      return TextField(
                                        decoration: InputDecoration(
                                          hintText: e,
                                        ),
                                        onChanged: (value) {
                                          coverLetterPlaceholderReplacementMap[
                                              e] = value;
                                        },
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }
}

class PlaceholderForm extends StatefulWidget {
  const PlaceholderForm({
    Key? key,
    required this.coverLetterPlaceholders,
    required this.emailTemplatePlaceholders,
  }) : super(key: key);

  final List<String> coverLetterPlaceholders;
  final List<String> emailTemplatePlaceholders;

  @override
  State<PlaceholderForm> createState() => _PlaceholderFormState();
}

class _PlaceholderFormState extends State<PlaceholderForm> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [...widget.coverLetterPlaceholders.map((e) => Text(e))],
        ),
        Column(
          children: [...widget.emailTemplatePlaceholders.map((e) => Text(e))],
        ),
      ],
    );
  }
}
