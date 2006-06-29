use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Module::List",
	VERSION_FROM => "lib/Module/List.pm",
	PREREQ_PM => {
		"IO::Dir" => "1.03",
	},
);
