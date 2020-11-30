using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class CommentFacade
    {
        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public int Save(Comment model, string userName)
        {
            model.CreateBy = userName;
            model.CreateDate = System.DateTime.Now;
            CommentRepository commentRepository = new CommentRepository();
            return commentRepository.Save(model);
        }

        /// <summary>
        /// Gets the specified record ID.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        public List<Comment> Get(int recordID, string entityName)
        {
            
            CommentRepository commentRepository = new CommentRepository();
            List<Comment> comments = new List<Comment>();
            if (recordID > 0)
            {
                comments = commentRepository.Get(recordID, entityName);
            }
            
            return comments;
        }

        /// <summary>
        /// Saves the specified comment type.
        /// </summary>
        /// <param name="commentType">Type of the comment.</param>
        /// <param name="entity">The entity.</param>
        /// <param name="recordId">The record id.</param>
        /// <param name="description">The description.</param>
        /// <param name="createdBy">The created by.</param>
        /// <returns></returns>
        public int Save(string commentType, string entity, int recordId, string description, string createdBy)
        {
            CommentRepository commentRepository = new CommentRepository();
            return commentRepository.Save(commentType, entity, recordId, description, createdBy);
        }

        /// <summary>
        /// Updates the comment.
        /// </summary>
        /// <param name="commentId">The comment id.</param>
        /// <param name="commentText">The comment text.</param>
        public void UpdateComment(int commentId, string commentText)
        {
            CommentRepository commentRepository = new CommentRepository();
            commentRepository.UpdateComment(commentId, commentText);
        }
    }
}
