using Microsoft.EntityFrameworkCore;
using Music_IBook_API.Models;
using System.Linq.Expressions;

namespace Music_IBook_API.Repositories;

public class Repository<T> : IRepository<T> where T : class
{
    private readonly MusicIBookDbContext db;

    public Repository(MusicIBookDbContext db)
    {
        this.db = db;
    }

    public async Task<List<T>> GetAllAsync()
    {
        return await db.Set<T>().ToListAsync();
    }

    public async Task<T?> GetByIdAsync(long id)
    {
        return await db.Set<T>().FindAsync(id);
    }

    public async Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate)
    {
        return await db.Set<T>().FirstOrDefaultAsync(predicate);
    }

    public async Task AddAsync(T entity)
    {
        await db.Set<T>().AddAsync(entity);
    }

    public void Update(T entity)
    {
        db.Set<T>().Update(entity);
    }

    public void Delete(T entity)
    {
        db.Set<T>().Remove(entity);
    }

    public async Task SaveChangesAsync()
    {
        await db.SaveChangesAsync();
    }
}