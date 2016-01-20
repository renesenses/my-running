DROP TABLE IF EXISTS authorAuthor;
CREATE TABLE author (
	author_id			BINARY(8)	PRIMARY KEY		NOT NULL,
	author_name 		TEXT 						NOT NULL
); 

CREATE TABLE plan (
	plan_id				BINARY(8)	PRIMARY KEY		NOT NULL,
	plan_name 			TEXT 						NOT NULL,
	plan_authorname 	TEXT 						NOT NULL,
	FOREIGN KEY(plan_authorname ) REFERENCES author(author_name)	
); 

DROP TABLE IF EXISTS base;
CREATE TABLE IF NOT EXISTS base (
	base_lib			TEXT		PRIMARY KEY		NOT NULL,
	base_type			CHAR(1)						NOT NULL	DEFAULT 'b' CHECK(base_type = 'b'),
	base_proglib		TEXT						NOT NULL,
	base_allureid		TEXT						NOT NULL,
	CONSTRAINT ctbasetype UNIQUE (base_lib, base_type),
	FOREIGN KEY(base_lib, base_type, base_proglib) REFERENCES step(step_lib, step_type, step_proglib),
	FOREIGN KEY(base_allureid) REFERENCES allure(allure_id)
);

DROP TABLE IF EXISTS fractionne;
CREATE TABLE IF NOT EXISTS fractionne (
	frac_lib		TEXT		PRIMARY KEY		NOT NULL,
	frac_type		CHAR(1)						NOT NULL	DEFAULT 'f' CHECK(frac_type = 'f'),
	frac_proglib		TEXT					NOT NULL,
	frac_repets		INTEGER						NOT NULL CHECK(frac_repets >= 0),
	frac_hduration	DATE						NOT NULL,
	frac_hallureid	TEXT						NOT NULL,
	frac_lduration	DATE						NOT NULL,
	frac_lallureid	TEXT						NOT NULL,
	CONSTRAINT ctfractype UNIQUE (frac_lib, frac_type),
	FOREIGN KEY(frac_lib, frac_type, frac_proglib) REFERENCES step(step_lib, step_type, step_proglib),
	FOREIGN KEY(frac_hallureid) REFERENCES allure(allure_id),
	FOREIGN KEY(frac_lallureid) REFERENCES allure(allure_id)
);

DROP TABLE IF EXISTS step;
CREATE TABLE IF NOT EXISTS step (
	step_lib		TEXT		PRIMARY KEY		NOT NULL,
	step_type		CHAR(1)						NOT NULL DEFAULT 'b' CHECK(step_type in ('b','f')),
	step_proglib	TEXT						NOT NULL,
	step_duration	DATE						NOT NULL,
	step_tolerance  INTEGER						NOT NULL CHECK(step_tolerance >= 0 AND step_tolerance <= 100),
	CONSTRAINT ctstep UNIQUE (step_lib, step_type, step_proglib),
	FOREIGN KEY(step_proglib) REFERENCES programme(prog_lib)
);

DROP TABLE IF EXISTS programme;
CREATE TABLE IF NOT EXISTS programme (
	prog_id			BINARY(8)	PRIMARY KEY		NOT NULL,
	prog_lib		TEXT						NOT NULL,
	prog_planid		BINARY(8)					NOT NULL,
	prog_week		INTEGER						NOT NULL CHECK(prog_week >= 1 AND prog_day <= 52),
	prog_day		INTEGER						NOT NULL CHECK(prog_day >= 1 AND prog_day <= 7),
	CONSTRAINT ctprog UNIQUE (prog_id, prog_planid, prog_week, prog_day),
	FOREIGN KEY(prog_planid) REFERENCES plan(plan_id)
);



DROP TABLE IF EXISTS allure;
CREATE TABLE IF NOT EXISTS allure (
	allure_id					INTEGER			PRIMARY KEY		NOT NULL,
	allure_lib					TEXT							NOT NULL,	
	allure_vitesse				NUMERIC(2,5)					NOT NULL,
	allure_tkilo				NUMERIC(2,2)					NOT NULL
);