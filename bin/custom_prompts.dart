 

class PromptStringsTemplate {
  Map<String, String> promptStrings;

  PromptStringsTemplate._internal(this.promptStrings);

  factory PromptStringsTemplate.withInfo(final String name, final String age) {
    final promptStrings = {'name': name, 'age': age};
    return PromptStringsTemplate._internal(promptStrings);
  }

  // ...
}

String str = 
    '''

    '''
  ;