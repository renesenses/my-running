DROP TABLE IF EXISTS authorAuthor;
CREATE TABLE author (
	author_id						INTEGER		PRIMARY KEY		NOT NULL,
	author_name 					TEXT 						NOT NULL
); 

CREATE TABLE plan (
	plan_id						TEXT		PRIMARY KEY		NOT NULL,
	plan_name 					TEXT 						NOT NULL,
	plan_authorname 			TEXT 						NOT NULL,
	FOREIGN KEY(plan_authorname ) REFERENCES author(author_name)	
); 

DROP TABLE IF EXISTS base;
CREATE TABLE IF NOT EXISTS base (
	base_lib		TEXT		PRIMARY KEY		NOT NULL,
	base_planid		TEXT						NOT NULL,
	base_week		TEXT						NOT NULL,
	base_day		TEXT						NOT NULL,
	base_allureid	DATE						NOT NULL,
	base_duration	DATE						NOT NULL,
	CONSTRAINT ctbase UNIQUE (base_lib, base_planid, base_week, base_day),
	FOREIGN KEY(base_planid) REFERENCES plan(plan_id),
	FOREIGN KEY(base_allureid) REFERENCES allure(allure_id)
);

DROP TABLE IF EXISTS fractionne;
CREATE TABLE IF NOT EXISTS fractionne (
	frac_lib		TEXT		PRIMARY KEY		NOT NULL,
	frac_planid		TEXT						NOT NULL,
	frac_week		TEXT						NOT NULL,
	frac_day		TEXT						NOT NULL,
	frac_nbsteps	INTEGER						NOT NULL,
	frac_hduration	DATE						NOT NULL,
	frac_hallureid	DATE						NOT NULL,
	frac_lduration	DATE						NOT NULL,
	frac_lallureid	DATE						NOT NULL,
	frac_ecart		DATE						NOT NULL,
	frac_duration	DATE						NOT NULL,
	CONSTRAINT ctfractionne UNIQUE (frac_lib, frac_planid),
	FOREIGN KEY(frac_planid) REFERENCES plan(plan_id),
	FOREIGN KEY(frac_hallureid) REFERENCES allure(allure_id),
	FOREIGN KEY(frac_lallureid) REFERENCES allure(allure_id)
);

DROP TABLE IF EXISTS allure;
CREATE TABLE IF NOT EXISTS allure (
	allure_id					TEXT		PRIMARY KEY		NOT NULL,
	allure_vitesse				TEXT						NOT NULL,
	allure_tkilo				TEXT						NOT NULL
);