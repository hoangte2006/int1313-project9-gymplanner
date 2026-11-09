package com.gym.db;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Lop duy nhat biet cach noi vao CSDL. Cac lop DAO chi goi DbConnection.get().
 * Thong tin ket noi doc tu db.properties (khong dua mat khau vao code).
 */
public final class DbConnection {

    private static final Properties PROPS = load();

    private DbConnection() { }

    private static Properties load() {
        Properties p = new Properties();
        try (InputStream in = DbConnection.class.getResourceAsStream("/db.properties")) {
            if (in == null) {
                throw new IllegalStateException(
                    "db.properties not found. Copy db.properties.example to db.properties "
                    + "in src/main/resources and fill in your own connection details.");
            }
            p.load(in);
        } catch (IOException e) {
            throw new IllegalStateException("Cannot read db.properties", e);
        }
        return p;
    }

    /** Mo mot ket noi moi. Noi goi phai dong ket noi (dung try-with-resources). */
    public static Connection get() throws SQLException {
        return DriverManager.getConnection(
            PROPS.getProperty("db.url"),
            PROPS.getProperty("db.user"),
            PROPS.getProperty("db.password"));
    }
}
