can_publish:
	flutter upgrade && dart format --fix ./ && flutter analyze ./ && flutter test

publish:
	flutter upgrade && dart format --fix ./ && flutter analyze ./ && flutter test && flutter pub pub publish