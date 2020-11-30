using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class CommentRepository
    {
        /// <summary>
        /// Saves the specified comment.
        /// </summary>
        /// <param name="commentType">Type of the comment.</param>
        /// <param name="entity">The entity.</param>
        /// <param name="recordId">The record id.</param>
        /// <param name="description">The description.</param>
        /// <param name="createdBy">The created by.</param>
        public int Save(string commentType, string entity, int recordId, string description, string createdBy)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                int? commentTypeId = null;
                int? entityId = null;
                if (!string.IsNullOrEmpty(commentType))
                {
                    var commentTypeFromDB = dbContext.CommentTypes.Where(x => x.Name == commentType).FirstOrDefault();
                    if (commentTypeFromDB != null)
                    {
                        commentTypeId = commentTypeFromDB.ID;
                    }
                }
                var entityFromDB = dbContext.Entities.Where(x => x.Name == entity).FirstOrDefault();
                if (entityFromDB != null)
                {
                    entityId = entityFromDB.ID;
                }

                Comment c = new Comment();
                c.CommentTypeID = commentTypeId;
                c.EntityID = entityId;
                c.CreateBy = createdBy;
                c.CreateDate = DateTime.Now;
                c.RecordID = recordId;
                c.Description = description;

                dbContext.Comments.Add(c);
                dbContext.SaveChanges();

                return c.ID;
            }

        }

        /// <summary>
        /// Saves the specified comment (updates if one already exists).
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public int Save(Comment model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var comment = dbContext.Comments.Where(x => x.RecordID == model.RecordID && x.EntityID == model.EntityID).FirstOrDefault();

                if (comment == null)
                {
                    dbContext.Comments.Add(model);
                    dbContext.Entry(model).State = EntityState.Added;
                }
                else
                {
                    comment.Description = model.Description;
                    dbContext.Entry(comment).State = EntityState.Modified;
                }

                dbContext.SaveChanges();
                return model.ID;
            }
        }

        /// <summary>
        /// Gets the specified record id.
        /// </summary>
        /// <param name="recordId">The record id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        public List<Comment> Get(int recordId, string entityName)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                var result = entities.Comments.Where(r => r.RecordID == recordId && r.Entity.Name == entityName).OrderByDescending(d => d.CreateDate);
                return result.ToList<Comment>();
            }
        }

        /// <summary>
        /// Updates the comment.
        /// </summary>
        /// <param name="commentId">The comment id.</param>
        /// <param name="commentText">The comment text.</param>
        public void UpdateComment(int commentId, string commentText)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.Comments.Where(r => r.ID == commentId).FirstOrDefault();
                if (result != null)
                {
                    result.Description = commentText;
                    dbContext.SaveChanges();
                }
            }
        }

    }
}
