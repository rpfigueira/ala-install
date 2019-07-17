--  Function used for full DB exports
CREATE OR REPLACE FUNCTION export_images() RETURNS void AS $$
    BEGIN
        COPY  
        (
            select
            data_resource_uid AS "dataResourceUid",
            split_part(original_filename, '||', 2) AS "occurrenceID",
            CONCAT( '{{images_base_url}}{{images_context_path}}/image/proxyImageThumbnailLarge?imageId=', image_identifier) AS identifier,
            regexp_replace(regexp_replace(creator, E'[\\n\\r]+', ' ', 'g' ) AS creator,
            date_taken AS created,
            regexp_replace(title, E'[\\n\\r]+', ' ', 'g' ) AS title,
            mime_type AS format,
            regexp_replace(license, E'[\\n\\r]+', ' ', 'g' ) AS license,
            regexp_replace(rights, E'[\\n\\r]+', ' ', 'g' ) AS rights,
            regexp_replace(rights_holder, E'[\\n\\r]+', ' ', 'g' ) AS "rightsHolder",
            CONCAT('{{images_base_url}}{{images_context_path}}/image/details/', image_identifier) AS "references",
            regexp_replace(title, E'[\\n\\r]+', ' ', 'g' ) as title,
            regexp_replace(description, E'[\\n\\r]+', ' ', 'g' ) as description,
            extension as extension,
            l.acronym  as "recognisedLicense",
            i.date_deleted as "dateDeleted",
            contentmd5hash as md5hash,
            file_size as "fileSize",
            width as width,
            height as height,
            zoom_levels as "zoomLevels",
            image_identifier as "imageIdentifier"
            from image i
            left outer join license l ON l.id = i.recognised_license_id
            order by data_resource_uid
        )
        TO '{{images_export_dir}}/images.csv' DELIMITER ',' CSV HEADER;
    END;
$$ LANGUAGE plpgsql;

--  Function used for regeneration of elastic search index
CREATE OR REPLACE FUNCTION export_index() RETURNS void AS $$
BEGIN
    COPY
        (
        select
            image_identifier as "imageIdentifier",
            contentmd5hash as "contentmd5hash",
            contentsha1hash as "contentsha1hash",
            mime_type AS format,
            original_filename AS originalFilename,
            extension as extension,
            date_uploaded AS "dateUploaded",
            date_taken AS created,
            file_size as "fileSize",
            height as height,
            width as width,
            zoom_levels as "zoomLevels",
            data_resource_uid AS "dataResourceUid",
            regexp_replace(regexp_replace(creator, '[|''"&]+',''), E'[\\n\\r]+', ' ', 'g' ) AS creator,
            regexp_replace(regexp_replace(title, '[|''"&]+',''), E'[\\n\\r]+', ' ', 'g' ) AS title,
            regexp_replace(regexp_replace(description, '[|''"&]+',''), E'[\\n\\r]+', ' ', 'g' )  AS title,
            regexp_replace(regexp_replace(rights, '[|''"&]+',''), E'[\\n\\r]+', ' ', 'g' )  AS rights,
            regexp_replace(regexp_replace(rights_holder, '[|''"&]+',''), E'[\\n\\r]+', ' ', 'g' )  AS "rightsHolder",
            regexp_replace(regexp_replace(license, '[|''"&]+',''), E'[\\n\\r]+', ' ', 'g' )  AS license,
            thumb_height AS "thumbHeight",
            thumb_width AS "thumbWidth",
            harvestable,
            l.acronym  as "recognisedLicense",
            split_part(original_filename, '||', 2) AS "occurrenceID"
        from image i
        left outer join license l ON l.id = i.recognised_license_id
        where date_deleted is NULL
        )
        TO '{{images_export_dir}}/images-index.csv' WITH CSV DELIMITER '$' HEADER;
END;
$$ LANGUAGE plpgsql;
