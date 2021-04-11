import 'dart:convert';
import 'dart:html';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cbp/Services/CbpCreator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:html' as html;

const List<String> headerExtenstions = ['.hpp', '.h', '.hh'];
const List<String> sourceExtensions = ['.cpp', '.cxx', '.c'];
List<String> _headersAndSources = <String>[];

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlatformFile _pickedFile;
  Archive _archive;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Text(
                '''This is a very simple web application that can be used to create CodeBlocks projects.
Instructions:
1. Upload a ZIP file containing all your source files and header files.
2. Press the Create ZIP with CBP File button to download the new ZIP containing the .cbp file.
Please note that this tool creates only one project at a time, so don't upload a zip containing multiple standalone projects!

                ''',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text("Upload"),
                  onPressed: () {
                    _pickFile();
                  },
                ),
                IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext) {
                            return _headersAndSources.isNotEmpty
                                ? SimpleDialog(
                                    title: const Text(
                                        'Currently uploaded header and sources files'),
                                    children: List.generate(
                                        _headersAndSources.length,
                                        (index) => Card(
                                              child: Text(
                                                  _headersAndSources[index]),
                                            )))
                                : SimpleDialog(
                                    title: Container(
                                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                                    child: const Text(
                                        "There are currently no header or source files uploaded!"),
                                  ));
                          });
                    })
              ],
            ),
            TextButton(
              child: Text("Create ZIP with CBP File"),
              onPressed: () {
                if (_pickedFile != null) {
                  _processZipFile();
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          title: Text("ERROR"),
                          content:
                              Text("You need to upload a ZIP file first!"));
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  _pickFile() async {
    FilePickerResult result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result != null && result.files.first.extension == "zip") {
      _pickedFile = result.files.first;
      _archive = ZipDecoder().decodeBytes(_pickedFile.bytes);
      _headersAndSources.clear();
      for (var file in _archive) {
        var extension = p.extension(file.toString());
        if (headerExtenstions.contains(extension) ||
            sourceExtensions.contains(extension)) {
          _headersAndSources.add(file.toString());
        }
      }
    }
  }

  void _processZipFile() async {
    String projectName = _pickedFile.name.split('.')[0];

    String CBPFile = CbpCreator.createCBP(projectName, _headersAndSources);

    ArchiveFile a =
        ArchiveFile(projectName + ".cbp", 5000, utf8.encode(CBPFile));
    _archive.addFile(a);

    var zip_data = ZipEncoder().encode(_archive);

    final rawData = zip_data;
    final content = base64Encode(rawData);
    final anchor = AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", projectName + ".zip")
      ..click();
  }
}
