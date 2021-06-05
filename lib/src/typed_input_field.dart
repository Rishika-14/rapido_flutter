import 'package:flutter/material.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';
import 'package:rapido/rapido.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter/services.dart';
import 'package:passwordfield/passwordfield.dart';

/// Given a field name, returns an appropriately configured FormField,
/// possibly parented by another widget.
/// Types are inferred from fieldNames.
/// Field name ends in | inferred type
/// ends in "count" -> integer
/// ends in "amount" -> double
/// ends in "date" -> date
/// ends in "datetime" -> date and time
/// ends in "latlong" -> latitude and longitude
/// ends in "image" -> image
/// ends in "text" -> multiline string
/// ends in "?" -> boolean
/// ends in "secret" -> password string
/// All other fields return a single line text input field.
/// Optionally, you can provide an appropriate FieldOptions subclass object
/// to specify how to render the field.
class TypedInputField extends StatelessWidget {
  /// Options for configuring the InputField
  final FieldOptions? fieldOptions;

  /// The name of the field, used to calculate which type of input to return
  final String fieldName;

  /// The label to display in the UI for the specified fieldName
  final String label;

  /// Call back function invoked when the Form parent of the FormField is
  /// saved. The value returned is determined by the type of the field.
  final Function onSaved;

  /// The initial value to display in the FormField.
  final dynamic initialValue;

  TypedInputField(
    this.fieldName, {
    required this.label,
    required this.onSaved,
    required this.initialValue,
    this.fieldOptions,
  });

  @override
  Widget build(BuildContext context) {
    if (fieldOptions != null) {
      if (fieldOptions.runtimeType == InputListFieldOptions) {
        return _getListPickerFormField(fieldOptions);
      }
    }
    //done
    if (fieldName.toLowerCase().endsWith("count")) {
      return _getIntegerFormField();
    }
    //done
    if (fieldName.toLowerCase().endsWith("amount")) {
      return _getAmountFormField();
    }
    if (fieldName.toLowerCase().endsWith("datetime")) {
      String dateTimeFormat;
      if (fieldOptions != null) {
        dateTimeFormat = _getFormatStringFromOptions();
      } else {
        dateTimeFormat = "EEE, MMM d, y H:mm:s";
      }
      return _getDateTimeFormField(dateTimeFormat, false, context);
    }
    if (fieldName.toLowerCase().endsWith("date")) {
      String dateFormat;
      if (fieldOptions != null) {
        dateFormat = _getFormatStringFromOptions();
      } else {
        dateFormat = "yMd";
      }
      return _getDateTimeFormField(dateFormat, true, context);
    }
    //dont do for now
    if (fieldName.toLowerCase().endsWith("latlong")) {
      //work around json.decode reading _InternalHashMap<String, dynamic>
      Map<String, double> v;
      if (initialValue != null) {
        v = Map<String, double>.from(initialValue);
      }
      return MapPointFormField(fieldName, label: label, initialValue: v,
          onSaved: (Map<String, double> value) {
        this.onSaved(value);
      });
    }

    if (fieldName.toLowerCase().endsWith("image")) {
      return ImageFormField(
        fieldName,
        initialValue: initialValue,
        label: label,
        onSaved: (String value) {
          this.onSaved(value);
        },
      );
    }

    //done
    if (fieldName.toLowerCase().endsWith("text")) {
      return _getTextFormField(lines: 10);
    }

    if (fieldName.toLowerCase().endsWith("?")) {
      return BooleanFormField(
        fieldName,
        label: label,
        initialValue: initialValue,
        onSaved: (bool value) {
          this.onSaved(value);
        },
      );
    }

    if (fieldName.toLowerCase().endsWith("secret")) {
      return SecretFormField(
        initialValue: initialValue,
        onSaved: onSaved,
        label: label,
      );
    }

    return _getTextFormField();
  }

  String _getFormatStringFromOptions() {
    late final String dateTimeFormat;
    if (fieldOptions != null &&
        fieldOptions.runtimeType == DateTimeFieldOptions) {
      DateTimeFieldOptions fo = fieldOptions as DateTimeFieldOptions;
      dateTimeFormat = fo.formatString;
    }
    return dateTimeFormat;
  }

  Widget _getTextFormField({int lines: 1}) {
    return TextFormField(
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
        initialValue: initialValue,
        onSaved: (String? value) {
          this.onSaved(value);
        });
  }

  ListPickerFormField _getListPickerFormField(
      InputListFieldOptions fieldOptions) {
    return ListPickerFormField(
      documentList: fieldOptions.documentList,
      displayField: fieldOptions.displayField,
      valueField: fieldOptions.valueField,
      label: label,
      initiValue: initialValue,
      onSaved: (dynamic value) {
        this.onSaved(value);
      },
    );
  }

  DateTimeField _getDateTimeFormField(
      formatString, dateOnly, BuildContext context) {
    DateFormat format = DateFormat(formatString);
    return DateTimeField(
      onShowPicker: (context, currentValue) async {
        DateTime inputValue;
        DateTime date = await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            initialDate: currentValue ?? DateTime.now(),
            lastDate: DateTime(2100));
        inputValue = date;
        if (!dateOnly) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
          );
          inputValue = DateTimeField.combine(date, time);
        }
        return inputValue;
      },
      format: format,
      decoration: InputDecoration(labelText: label),
      onSaved: (DateTime value) {
        String v = format.format(value);
        this.onSaved(v);
      },
      initialValue: _formatInitialDateTime(format),
    );
  }

  DateTime _formatInitialDateTime(DateFormat format) {
    if (initialValue == null) {
      return DateTime.now();
    } else {
      DateTime dt = format.parse(initialValue);
      return dt;
    }
  }

  Widget _getIntegerFormField() {
    if (fieldOptions != null) {
      if (fieldOptions.runtimeType == IntegerPickerFieldOptions) {
        IntegerPickerFieldOptions fo =
            fieldOptions as IntegerPickerFieldOptions;

        if (fo.minimum != null && fo.maximum != null) {
          return IntegerPickerFormField(
            label: label,
            initialValue: initialValue,
            fieldOptions: fo,
            onSaved: (int val) {
              this.onSaved(val);
            },
          );
        }
      }
    }

    return TextFormField(
      decoration: InputDecoration(labelText: label),
      initialValue: initialValue == null ? "0" : initialValue.toString(),
      onSaved: (String value) {
        this.onSaved(int.parse(value));
      },
      keyboardType:
          TextInputType.numberWithOptions(signed: false, decimal: false),
      inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
    );
  }

  Widget _getAmountFormField() {
    bool signed = false;
    if (fieldOptions.runtimeType == AmountFieldOptions) {
      AmountFieldOptions fo = fieldOptions as AmountFieldOptions;
      signed = fo.allowNegatives ?? false;
    }
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      initialValue: initialValue == null ? "0" : initialValue.toString(),
      onSaved: (String? value) {
        this.onSaved(value == null ? null : double.parse(value));
      },
      keyboardType:
          TextInputType.numberWithOptions(signed: signed, decimal: true),
    );
  }
}

/// A FormField for setting secrets such as passwords and tokens.
/// Provides a text field that is masked by default but that
/// the user can toggle.
class SecretFormField extends StatefulWidget {
  final String initialValue;
  final Function onSaved;
  final String label;

  const SecretFormField({
    @required this.initialValue,
    @required this.onSaved,
    @required this.label,
  });

  @override
  State<StatefulWidget> createState() {
    return new _SecretFormFieldState();
  }
}

class _SecretFormFieldState extends State<SecretFormField> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormField(
      builder: (FormFieldState<String> state) {
        return PasswordField(
          hintText: widget.label,
          controller: controller,
        );
      },
      onSaved: (String val) {
        widget.onSaved(controller.text);
      },
    );
  }
}

/// A FormField for choosing integer values, rendered
/// as a spinning chooser. You must provide a map
/// of field options that include min and max, in the form of:
/// fieldOptions: {"min":0,"max":10}, in order to provide a
/// FormField limited to 0 through 10.
class IntegerPickerFormField extends StatefulWidget {
  const IntegerPickerFormField({
    Key key,
    required this.initialValue,
    required this.fieldOptions,
    required this.onSaved,
    required this.label,
  }) : super(key: key);

  final IntegerPickerFieldOptions fieldOptions;
  final Function onSaved;
  final int initialValue;
  final String label;

  @override
  _IntegerPickerFormFieldState createState() {
    return new _IntegerPickerFormFieldState();
  }
}

class _IntegerPickerFormFieldState extends State<IntegerPickerFormField> {
  int _currentValue = 0;

  @override
  void initState() {
    widget.initialValue == null
        ? _currentValue = widget.fieldOptions.minimum ?? 0
        : _currentValue = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FormFieldCaption(widget.label),
        FormField(
          builder: (FormFieldState<int> state) {
            return NumberPicker(
              value: _currentValue,
              maxValue: widget.fieldOptions.maximum ?? double.infinity as int,
              minValue:
                  widget.fieldOptions.minimum ?? -(double.infinity as int),
              onChanged: (int val) {
                setState(() {
                  _currentValue = val;
                });
              },
            );
          },
          onSaved: (int? val) {
            widget.onSaved(_currentValue);
          },
        ),
      ],
    );
  }
}

/// A widget for captioning fields in DocumentForm and DocumentPage.
class FormFieldCaption extends StatelessWidget {
  const FormFieldCaption(this.label, {Key key}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label == null) return Container();
    return Text(
      label,
      style: Theme.of(context).textTheme.caption,
      textAlign: TextAlign.start,
    );
  }
}
