#### functions

-- DROP FUNCTION analytics.sync_environments();

CREATE OR REPLACE FUNCTION analytics.sync_environments()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Insert the new environment into environments if it doesn't exist
    INSERT INTO analytics.environments (tenant_id, environment_name)
    SELECT NEW.tenant_id, NEW.environment_name
    WHERE NOT EXISTS (
        SELECT 1 FROM analytics.environments 
        WHERE tenant_id = NEW.tenant_id AND environment_name = NEW.environment_name
    );
    RETURN NEW;
END;
$function$
;


-- DROP FUNCTION analytics.update_environments();

CREATE OR REPLACE FUNCTION analytics.update_environments()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE environments 
    SET environment_name = NEW.environment_name
    WHERE tenant_id = NEW.tenant_id AND environment_name = OLD.environment_name;
    RETURN NEW;
END;
$function$
;
---

### tables

-- analytics.applications definition

-- Drop table

-- DROP TABLE analytics.applications;

CREATE TABLE analytics.applications (
	application_id varchar(100) DEFAULT nextval('analytics.applications_application_id_seq'::regclass) NOT NULL,
	application_name varchar(100) NULL,
	namespace_id int4 NULL,
	tenant_id int4 NULL
);


-- analytics.applications foreign keys

ALTER TABLE analytics.applications ADD CONSTRAINT fk_namespace FOREIGN KEY (namespace_id) REFERENCES analytics.namespaces(namespace_id);
ALTER TABLE analytics.applications ADD CONSTRAINT fk_tenants2 FOREIGN KEY (tenant_id) REFERENCES analytics.tenants2(tenant_id);


-- analytics.deployments_statistics definition

-- Drop table

-- DROP TABLE analytics.deployments_statistics;

CREATE TABLE analytics.deployments_statistics (
	deployment_id serial4 NOT NULL,
	deployment_status varchar(100) NULL,
	deployment_start_time timestamp DEFAULT now() NULL,
	deployment_end_time timestamp DEFAULT now() NULL,
	recovery_start_time timestamp DEFAULT now() NULL,
	recovery_end_time timestamp DEFAULT now() NULL,
	environment_id int4 NULL,
	CONSTRAINT deployments_statistics_pkey PRIMARY KEY (deployment_id)
);

-- Permissions

ALTER TABLE analytics.deployments_statistics OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.deployments_statistics TO analytics_user;


-- analytics.deployments_statistics2 definition

-- Drop table

-- DROP TABLE analytics.deployments_statistics2;

CREATE TABLE analytics.deployments_statistics2 (
	deployment_id serial4 NOT NULL,
	deployment_status varchar(100) NULL,
	deployment_start_time timestamp DEFAULT now() NULL,
	deployment_end_time timestamp DEFAULT now() NULL,
	recovery_start_time timestamp DEFAULT now() NULL,
	recovery_end_time timestamp DEFAULT now() NULL,
	environment_id int4 NULL,
	CONSTRAINT deployments_statistics_pkey_1 PRIMARY KEY (deployment_id)
);

-- Permissions

ALTER TABLE analytics.deployments_statistics2 OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.deployments_statistics2 TO analytics_user;


-- analytics.descriptors_deployment definition

-- Drop table

-- DROP TABLE analytics.descriptors_deployment;

CREATE TABLE analytics.descriptors_deployment (
	deployment_id serial4 NOT NULL,
	descriptor_name varchar(100) NULL,
	pipeline_url varchar(100) NULL,
	CONSTRAINT deployments_statistics_pkey_1_1 PRIMARY KEY (deployment_id)
);

-- Permissions

ALTER TABLE analytics.descriptors_deployment OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.descriptors_deployment TO analytics_user;



-- analytics.environments definition

-- Drop table

-- DROP TABLE analytics.environments;

CREATE TABLE analytics.environments (
	environment_id serial4 NOT NULL,
	tenant_id int4 NOT NULL,
	environment_name varchar(100) NULL,
	CONSTRAINT environments_pkey PRIMARY KEY (environment_id),
	CONSTRAINT unique_environment UNIQUE (tenant_id, environment_name)
);

-- Permissions

ALTER TABLE analytics.environments OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.environments TO analytics_user;


-- analytics.environments foreign keys

ALTER TABLE analytics.environments ADD CONSTRAINT environments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES analytics.tenants(tenant_id) ON DELETE CASCADE;
ALTER TABLE analytics.environments ADD CONSTRAINT fk_tenant FOREIGN KEY (tenant_id) REFERENCES analytics.tenants(tenant_id) ON DELETE CASCADE;



-- analytics.environments2 definition

-- Drop table

-- DROP TABLE analytics.environments2;

CREATE TABLE analytics.environments2 (
	environment_id serial4 NOT NULL,
	tenant_id int4 NOT NULL,
	environment_name varchar(100) NULL,
	deployed_with varchar(100) NULL,
	namespace_id int4 NULL,
	CONSTRAINT environments_pkey_1 PRIMARY KEY (environment_id),
	CONSTRAINT unique_environment_1 UNIQUE (tenant_id, environment_name)
);

-- Permissions

ALTER TABLE analytics.environments2 OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.environments2 TO analytics_user;


-- analytics.environments2 foreign keys

ALTER TABLE analytics.environments2 ADD CONSTRAINT environments2_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES analytics.namespaces(namespace_id) ON DELETE CASCADE;
ALTER TABLE analytics.environments2 ADD CONSTRAINT environments2_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES analytics.tenants2(tenant_id) ON DELETE CASCADE;


-- analytics.tenants definition

-- Drop table

-- DROP TABLE analytics.tenants;

CREATE TABLE analytics.tenants (
	tenant_name varchar(100) NULL,
	environment_name varchar(100) NULL,
	last_checked timestamp DEFAULT now() NULL,
	environment_id serial4 NOT NULL,
	tenant_id serial4 NOT NULL,
	CONSTRAINT tenants_pkey PRIMARY KEY (tenant_id)
);

-- Table Triggers

create trigger trigger_sync_environments after
insert
    on
    analytics.tenants for each row execute function analytics.sync_environments();
create trigger trigger_update_environments after
update
    on
    analytics.tenants for each row execute function analytics.update_environments();

-- Permissions

ALTER TABLE analytics.tenants OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.tenants TO analytics_user;


-- analytics.tenants2 definition

-- Drop table

-- DROP TABLE analytics.tenants2;

CREATE TABLE analytics.tenants2 (
	tenant_name varchar(100) NULL,
	tenant_id int4 DEFAULT nextval('analytics.tenants_domains_tenant_id_seq'::regclass) NOT NULL,
	domain_id int4 NULL,
	CONSTRAINT tenants_pkey_1 PRIMARY KEY (tenant_id)
);

-- Permissions

ALTER TABLE analytics.tenants2 OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.tenants2 TO analytics_user;


-- analytics.domain_applications_view source

CREATE OR REPLACE VIEW analytics.domain_applications_view
AS SELECT d.domain_id,
    d.domain_name,
    t.tenant_id,
    t.tenant_name,
    e.environment_id,
    e.environment_name,
    ns.namespace_id,
    ns.namespace,
    a.application_id,
    a.application_name
   FROM analytics.domains d
     JOIN analytics.tenants2 t ON d.domain_id = t.domain_id
     LEFT JOIN analytics.environments2 e ON t.tenant_id = e.tenant_id
     LEFT JOIN analytics.namespaces ns ON e.environment_id = ns.environment_id
     LEFT JOIN analytics.applications a ON ns.namespace_id = a.namespace_id AND a.tenant_id = t.tenant_id;

-- Permissions

ALTER TABLE analytics.domain_applications_view OWNER TO analytics_user;
GRANT ALL ON TABLE analytics.domain_applications_view TO analytics_user;





