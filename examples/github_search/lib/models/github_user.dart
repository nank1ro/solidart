import 'package:json_annotation/json_annotation.dart';

part 'github_user.g.dart';

@JsonSerializable(createToJson: false)
class GithubUser {
  const GithubUser({
    required this.login,
    required this.avatarUrl,
  });

  factory GithubUser.fromJson(Map<String, dynamic> json) =>
      _$GithubUserFromJson(json);

  final String login;
  @JsonKey(name: 'avatar_url')
  final String avatarUrl;
}
