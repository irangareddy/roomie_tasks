import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('No commit message file provided.');
    exit(1);
  }

  final commitFile = File(arguments[0]);
  final commitMessage = commitFile.readAsStringSync();

  final regExp = RegExp(
    r'^(feat|fix|docs|style|refactor|perf|test|chore)(\(.+?\))?: .{1,50}',
  );

  if (!regExp.hasMatch(commitMessage)) {
    print('''
❌ Invalid commit message format.

Commit messages should be in the format:
<type>(<scope>): <subject>

Types:
• feat: A new feature
• fix: A bug fix
• docs: Documentation only changes
• style: Changes that do not affect the meaning of the code
• refactor: A code change that neither fixes a bug nor adds a feature
• perf: A code change that improves performance
• test: Adding missing tests or correcting existing tests
• chore: Changes to the build process or auxiliary tools and libraries

The scope is optional and should be a noun describing a section of the codebase.
The subject should use imperative, present tense: "change" not "changed" nor "changes".
The subject should not exceed 50 characters.

Example:
feat(auth): add user registration
''');
    exit(1);
  } else {
    print('✅ Commit message format is valid.');
  }
}