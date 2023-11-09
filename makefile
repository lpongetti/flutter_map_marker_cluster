can_publish:
	dart format --fix ./ && flutter analyze ./ && flutter test

publish:
	dart format --fix ./ && flutter analyze ./ && flutter test && flutter pub pub publish